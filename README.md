# RevDeBug Server docker-compose installation project

Please refer to installation manual at https://revdebug.gitbook.io/revdebug/installing-revdebug-server

This branch integrates RevDeBug ui with new Salamandra ui.

Use this command to start server sudo docker compose -f ./docker-compose.yml -f docker-compose-salamandra.yml  up -d

Remember to open port 52734 on machine as Salamandra uses it.
