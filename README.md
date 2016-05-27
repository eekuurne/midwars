# Course page
http://tkt-hon.github.io/midwars/

# tkt-hon Midwars Tourney

    Alias "create_midwars_botmatch_1v1" "set teambotmanager_legion; set teambotmanager_hellbourne; BotDebugEnable; StartGame practice test mode:botmatch map:midwars teamsize:1 spectators:1 allowduplicate:true; g_botDifficulty 3; g_camDistanceMax 10000; g_camDistanceMaxSpectator 10000;"
    Alias "create_midwars_botmatch" "set teambotmanager_legion; set teambotmanager_hellbourne; BotDebugEnable; StartGame practice test mode:botmatch map:midwars teamsize:5 spectators:1 allowduplicate:true; g_botDifficulty 3; g_camDistanceMax 10000; g_camDistanceMaxSpectator 10000;"

## Teams

		Alias "team_MidXORFeed_legion" "set teambotmanager_legion mid_xor_feed; AddBot 1 MidXORFeed_Valkyrie; AddBot 1 MidXORFeed_Devourer; AddBot 1 MidXORFeed_PuppetMaster; AddBot 1 MidXORFeed_Nymphora; AddBot 1 MidXORFeed_MonkeyKing;"

		Alias "team_MidXORFeed_hellbourne" "set teambotmanager_hellbourne mid_xor_feed; AddBot 2 MidXORFeed_Valkyrie; AddBot 2 MidXORFeed_Devourer; AddBot 2 MidXORFeed_PuppetMaster; AddBot 2 MidXORFeed_Nymphora; AddBot 2 MidXORFeed_MonkeyKing;"

### Default bots by organizers

    Alias "team_default_legion" "set teambotmanager_legion default; AddBot 1 Default_Devourer; AddBot 1 Default_MonkeyKing; AddBot 1 Default_Nymphora; AddBot 1 Default_PuppetMaster; AddBot 1 Default_Valkyrie"

    Alias "team_default_hellbourne" "set teambotmanager_hellbourne default; AddBot 2 Default_Devourer; AddBot 2 Default_MonkeyKing; AddBot 2 Default_Nymphora; AddBot 2 Default_PuppetMaster; AddBot 2 Default_Valkyrie"
