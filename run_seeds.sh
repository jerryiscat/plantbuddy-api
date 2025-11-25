#!/bin/bash
# Helper script to run the seed data SQL file
# Usage: ./run_seeds.sh

# Database connection details (update these if needed)
DB_NAME="plantbuddy_db"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"

echo "🌱 Running PlantBuddy seed data..."
echo "Database: $DB_NAME"
echo ""

# Run the SQL file
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f 02_seeds.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Seed data loaded successfully!"
    echo ""
    echo "Verification:"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
        SELECT 'Plants' as table_name, COUNT(*) as count 
        FROM api_plant 
        WHERE user_id = (SELECT id FROM api_user WHERE username = 'zjasmine.2002')
        UNION ALL
        SELECT 'Schedules', COUNT(*) 
        FROM api_schedule 
        WHERE plant_id IN (SELECT id FROM api_plant WHERE user_id = (SELECT id FROM api_user WHERE username = 'zjasmine.2002'))
        UNION ALL
        SELECT 'Activity Logs', COUNT(*) 
        FROM api_activitylog 
        WHERE plant_id IN (SELECT id FROM api_plant WHERE user_id = (SELECT id FROM api_user WHERE username = 'zjasmine.2002'));
    "
else
    echo ""
    echo "❌ Error loading seed data. Please check your database connection."
    exit 1
fi

