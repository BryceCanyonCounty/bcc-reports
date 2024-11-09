CreateThread(function()
    -- Create the bcc_reports table if it doesn't exist
    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_reports` (
            `report_id` VARCHAR(36) NOT NULL,
            `title` VARCHAR(255) NOT NULL,
            `details` TEXT NOT NULL,
            `type` VARCHAR(50) NOT NULL,
            `player_id` INT(11) NOT NULL,
            `steamname` VARCHAR(255) NOT NULL,
            `charIdentifier` VARCHAR(255) NOT NULL,
            `firstname` VARCHAR(255) NOT NULL,
            `lastname` VARCHAR(255) NOT NULL,
            `completed` TINYINT(1) DEFAULT 0,
            `completed_by_steamname` VARCHAR(255) DEFAULT NULL,
            `completed_by_charid` VARCHAR(255) DEFAULT NULL,
            `completed_by_name` VARCHAR(255) DEFAULT NULL,
            `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP(),
            PRIMARY KEY (`report_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
    ]])

    -- Alter the steamname column to support utf8mb4 encoding for special characters
    MySQL.query.await([[ 
        ALTER TABLE bcc_reports 
        MODIFY steamname VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    ]])

    -- Print a success message to the console
    print("Database tables for \x1b[35m\x1b[1m*bcc-reports*\x1b[0m created or updated \x1b[32msuccessfully\x1b[0m.")
end)
