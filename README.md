GetDotaStats Stat-Achievements
=====

###About###
 - This repo allows mods to have achievement data. It would be most useful for RPGs.

# GetDotaStats - StatCollectionAchievements specs 1.0 #

## Client --> Server ##

#### LIST ####
|Field Name|Field DataType|Field Description
|----------|--------------|-----------------
|type      |String        |Always "LIST", as that's this packet
|modID     |String        |The modID allocated by GetDotaStats
|steamID   |Long          |The SteamID of the owner of this save.

#### SAVE ####
|Field Name     |Field DataType  |Field Description
|---------------|----------------|-----------------
|type           |String          |Always "SAVE", as that's this packet
|modID          |String          |The modID allocated by GetDotaStats
|steamID        |Long            |The SteamID of the owner of this save.
|achievementID  |Integer         |The achievement that got progress
|achievementValue|Integer |This will be the value of the achievement. (0,1) for booleans and the rest as integers.

## Server --> Client ##

#### save ####

|Field Name|Field DataType|Field Description
|----------|--------------|-----------------
|type      |String        |Either "success" or "failure"
|error     |String        |A string describing the error. Only useful for debugging purposes

#### list ####
|Field Name|Field DataType |Field Description
|----------|---------------|-----------------
|type      |String         |Always "list", as that's this packet
|jsonData  |AchievementInfo|Contains an array of all the achievement metadata.

## AchievementInfo
This will be a JSON array of the following  

|FieldName     |Field Datatype|Field Description
|--------------|--------------|-----------------
|achievementID  |Integer         |The achievement that got progress
|achievementValue |Integer       |How much progress does the user have (if complete, it will be the same value as max)

As an example,  
``` json
[
    {
        "achievementID" : 0,
        "achievementValue" : 1
    },
    {
        "achievementID" : 1,
        "achievementValue" : 0
    },
    {
        "achievementID" : 2,
        "achievementValue" : 9001
    }
]
```
In this example, it will have the following localization
```
"ACHIEVEMENT_0_NAME"        "F in Chemistry"
"ACHIEVEMENT_0_DESCRIPTION" "On day 1 of the Rat job, blow up the lab."

"ACHIEVEMENT_1_NAME"        "License to Kill"
"ACHIEVEMENT_1_DESCRIPTION" "Kill 378 enemies using the Gruber Kurz handgun."
```
And each achievement will have two images:  
* `resource/flash3/images/achievements/0_on.png`
* `resource/flash3/images/achievements/0_off.png`  
where 0 is the achievement ID

Each mod will have an achievement schema, that will define:

|FieldName     |Field Datatype|Field Description
|--------------|--------------|-----------------
|achievementID  |Integer         |The achievement identifier
|achievementHidden  |Integer         |Whether the achievement will be displayed to users that have not earnt it yet
|achievementMaxValue |Integer       |The value at which the achievement is earnt

An achievement is determined as earnt when the achievementValue is equal to or greater than the achievementMaxValue.

## Ports ##

* Test: 4448 (does not hit the database or give responses... it's purely to check the data you are communicating)
* Live: 4449 (in the future, will only report critical errors to reduce log size)
