# PlantBuddy Database Schema

## Database Structure

### Tables

#### 1. `users` (Django AbstractUser)
- `id` - Primary key
- `username` - Unique username
- `email` - Unique email address
- `password` - Hashed password
- Standard Django user fields

#### 2. `plants`
- `id` - Primary key
- `user_id` - Foreign key to users
- `name` - Plant name (CharField, max 100)
- `species` - Plant species (CharField, max 100, optional)
- `perenual_id` - External link to Perenual API (Integer, optional)
- `care_level` - Easy/Moderate/Hard (CharField, optional)
- `image_url` - Plant photo URL (TextField, optional)
- `care_tips` - Care instructions (TextField, optional)
- `is_dead` - Boolean flag for graveyard (default: False)
- `created_at` - Timestamp
- `updated_at` - Timestamp

#### 3. `schedules` (The Rules Engine)
- `id` - Primary key
- `plant_id` - Foreign key to plants
- `task_type` - WATER, FERTILIZE, REPOTTING, PRUNE
- `frequency_days` - Number of days between tasks
- `next_due_date` - When the next task is due
- `is_active` - Boolean flag (default: True)
- `created_at` - Timestamp
- `updated_at` - Timestamp
- **Unique constraint**: (plant_id, task_type)

#### 4. `activity_logs` (The History Book)
- `id` - Primary key
- `plant_id` - Foreign key to plants
- `schedule_id` - Foreign key to schedules (nullable)
- `action_type` - WATER, FERTILIZE, REPOTTING, PRUNE, SNOOZE, SKIPPED_RAIN, PHOTO, NOTE
- `action_date` - When the action occurred
- `notes` - Optional notes (TextField)
- `previous_due_date` - Stored for undo functionality (Date, nullable)
- `created_at` - Timestamp

## API Endpoints

### Group A: My Jungle (Plants)

#### `GET /api/plants/`
- Returns all plants for the authenticated user where `is_dead = False`
- Includes joined schedule data showing `next_water_date`
- Response includes full plant data with schedules

#### `POST /api/plants/`
- Creates a new plant
- Optional: Creates default water schedule if `frequency_days` provided
- Body: `{ "name": "...", "species": "...", "perenual_id": 123, "care_level": "easy", "frequency_days": 7 }`

#### `GET /api/plants/{id}/`
- Get specific plant details

#### `PUT /api/plants/{id}/`
- Update plant information

#### `DELETE /api/plants/{id}/`
- Delete a plant

#### `GET /api/plants/graveyard/`
- Returns all plants where `is_dead = True`
- Custom action endpoint

### Group B: The Tasks (Daily Work)

#### `GET /api/tasks/today/`
- Queries schedules where `next_due_date <= TODAY()`
- Returns list of tasks with plant information
- Sorted: overdue first, then by due date
- Response format:
```json
[
  {
    "id": 1,
    "plant_id": 5,
    "plant_name": "Monstera",
    "task_type": "WATER",
    "due_date": "2025-02-20",
    "frequency_days": 7,
    "schedule_id": 1,
    "is_overdue": false
  }
]
```

#### `POST /api/plants/{id}/action/` (Most Important Endpoint)
- Records an action and updates schedules
- Body: `{ "action_type": "WATER", "notes": "Optional notes" }`
- Action types:
  - `WATER` - Standard watering
  - `FERTILIZE` - Adding nutrients
  - `REPOTTING` - Changing soil/pot
  - `PRUNE` - Cutting leaves
  - `SNOOZE` - Delaying task by 1 day
  - `SKIPPED_RAIN` - Nature watered it
  - `PHOTO` - Journal entry, no task
  - `NOTE` - Text observation

**Smart Logic:**
- `WATER`/`FERTILIZE`: Calculates new date = Today + frequency_days
- `SNOOZE`: Sets next_due_date = Today + 1 day
- `SKIPPED_RAIN`: Treats as completed, reschedules normally
- `PHOTO`/`NOTE`: No schedule changes

#### `POST /api/plants/{id}/undo/`
- Deletes the most recent activity_log for the plant
- Reverts schedule date to previous_due_date
- Returns updated schedule information

#### `POST /api/plants/{id}/mark_dead/`
- Marks plant as dead (`is_dead = True`)
- Deactivates all schedules for the plant
- Moves plant to graveyard

### Group C: External Data

#### `GET /api/search/perenual?q=monstera`
- Proxy endpoint to Perenual API
- Hides API key from client
- Returns plant data from Perenual
- Requires `PERENUAL_API_KEY` in settings

## Smart Logic Rules

### Rule 1: The Watering Math
**Scenario**: User waters a plant today (Nov 21). Frequency is 7 days.

**Calculation**: Nov 21 + 7 days = Nov 28

**Database Update**: 
```sql
UPDATE schedules 
SET next_due_date = '2025-11-28' 
WHERE plant_id = X AND task_type = 'WATER'
```

### Rule 2: The "Snooze" Math
**Scenario**: User hits "Snooze".

**Calculation**: Current Date + 1 day

**Database Update**: 
```sql
UPDATE schedules 
SET next_due_date = CURRENT_DATE + INTERVAL '1 day'
WHERE plant_id = X AND task_type = 'WATER'
```

### Rule 3: The "Graveyard" Logic
**Scenario**: User marks plant as Dead.

**Database Update**: 
```sql
UPDATE plants SET is_dead = TRUE WHERE id = X;
UPDATE schedules SET is_active = FALSE WHERE plant_id = X;
```

## Migration Instructions

1. **Create migrations:**
   ```bash
   cd plantbuddy-api
   python3 manage.py makemigrations
   ```

2. **Apply migrations:**
   ```bash
   python3 manage.py migrate
   ```

3. **Note**: This will create new tables and remove the old `Task` model. Existing data will be lost unless you create a data migration.

## Configuration

### Perenual API Key
Add to `plantbuddy/settings.py`:
```python
PERENUAL_API_KEY = 'your-api-key-here'
```

Get your API key from: https://perenual.com/api/docs

## Example Usage

### Create a plant with schedule:
```bash
POST /api/plants/
{
  "name": "Monstera",
  "species": "Monstera Deliciosa",
  "frequency_days": 7
}
```

### Water a plant:
```bash
POST /api/plants/1/action/
{
  "action_type": "WATER",
  "notes": "Watered thoroughly"
}
```

### Get today's tasks:
```bash
GET /api/tasks/today/
```

### Undo last action:
```bash
POST /api/plants/1/undo/
```

