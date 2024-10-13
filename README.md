# bcc-reports

## Description
bcc-reports is a comprehensive reporting system designed for RedM servers This system allows players to create detailed reports directly in-game, and admins can review, manage, and act on these reports. It supports multiple report types, such as player reports, bug reports, and staff reports, and integrates seamlessly with Discord for notification of new reports. The system is built with flexibility in mind, supporting localization and customization to fit server-specific needs.

## Features
- **Player Reporting**: Players can submit reports directly through an in-game menu.
- **Admin Management**: Admins can view, delete, and take action on reports via a dedicated admin panel.
- **Report Types**: Multiple report types including player, bug, staff, and other reports.
- **Discord Integration**: Sends notifications to a configured Discord webhook when a new report is submitted.
- **Localization**: Full localization support for different languages, including pre-configured Romanian language support.
- **Automatic Database Setup**: No manual database creation needed; the system automatically sets up the required tables.
- **Job-Based Admin Access**: Only admins with the correct roles can access the report management tools.
- **Easy Configuration**: Highly customizable via the `config.lua` file.

## Dependencies
- [vorp_core](https://github.com/VORPCORE/vorp-core-lua) - Core framework for RedM servers.
- [vorp_inventory](https://github.com/VORPCORE/vorp_inventory-lua) - Inventory system required for certain functionalities.
- [vorp_character](https://github.com/VORPCORE/vorp_character-lua) - Character management and job roles.
- [feather-menu](https://github.com/feather-framework/feather-menu) - Feather menu system for interactive UI.
- [bcc-utils](https://github.com/BryceCanyonCounty/bcc-utils) - Utility script for Discord integration and other functions.
- [oxmysql](https://github.com/overextended/oxmysql) - MySQL database integration for saving reports and related data.

## Installation
1. Download or clone the `bcc-reports` folder and place it in your server's `resources` directory.
2. Add `ensure bcc-reports` to your `server.cfg` file to make sure the resource is loaded when the server starts.
3. Ensure that all dependencies (VORP core, VORP inventory, oxmysql, feather-menu, etc.) are properly installed on your server.
4. Customize the system by editing the `config.lua` file, including setting up your desired report types, Discord webhook settings, and language localization.
5. The system automatically handles database setup—no manual creation of tables is required.
6. Restart your server to initialize `bcc-reports`.

## Usage

### Player Commands:
- `/report`: Opens the report creation menu for players to submit a new report.
  
### Admin Commands:
- `/view-reports`: Opens the admin menu to view and manage submitted reports.

Once a report is submitted, admins are notified via Discord if configured, and they can take action from the in-game admin panel, including deleting reports or teleporting to players.

## Side Notes
- If you need assistance or want to stay updated with the latest features, join the [bcc Discord community](https://discord.gg/VrZEEpBgZJ) for support and updates.
