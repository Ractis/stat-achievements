﻿package  {

	import flash.display.MovieClip;
	import flash.net.Socket;
    import flash.utils.ByteArray;
    import flash.events.Event;
    import flash.events.ProgressEvent;
    import flash.events.IOErrorEvent;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
	
	import com.adobe.serialization.json.JSONEncoder;
	import com.adobe.serialization.json.JSONParseError;
	import com.adobe.serialization.json.JSONDecoder;
	
    public class StatsCollectionAchievement extends MovieClip {
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;
		
		var SteamID:Number;

		var sock:Socket;
		var callback:Function;
		
		var json:String;

		var SERVER_ADDRESS:String = "176.31.182.87";
		var SERVER_PORT:Number = 4448;

		var achievementUI:AchievementUI;

        public function onLoaded() : void {
            // Tell the user what is going on
            trace("##Loading StatsCollectionAchivements...");

            // Reset our json
            json = '';

            // Load KV
            var settings = globals.GameInterface.LoadKVFile('scripts/stat_collection_achievement.kv');  
            // Load the live setting
            var live:Boolean = (settings.live == "1");

            // Load the settings for the given mode
            if(live) {
                // Load live settings
                SERVER_ADDRESS = settings.SERVER_ADDRESS_LIVE;
                SERVER_PORT = parseInt(settings.SERVER_PORT_LIVE);

                // Tell the user it's live mode
                trace("StatsCollectionRPG is set to LIVE mode.");
            } else {
                // Load live settings
                SERVER_ADDRESS = settings.SERVER_ADDRESS_TEST;
                SERVER_PORT = parseInt(settings.SERVER_PORT_TEST);

                // Tell the user it's test mode
                trace("StatsCollectionRPG is set to TEST mode.");
            }
            // Log the server
            trace("Server was set to "+SERVER_ADDRESS+":"+SERVER_PORT);

            // Create UI module
            achievementUI = new AchievementUI( gameAPI, globals );
            addChild( achievementUI );

            // Hook the stat collection event
			gameAPI.SubscribeToGameEvent("stat_collection_steamID", this.statCollectSteamID);
			gameAPI.SubscribeToGameEvent("stat_ach_load", statAchievementLoad);
			gameAPI.SubscribeToGameEvent("stat_ach_send", statAchievementSend);
        }
		private function ServerConnect(serverAddress:String, serverPort:int) {
			// Tell the client
			trace("##STATS Sending payload:");
			trace(json);

            // Create the socket
			sock = new Socket();
			sock.timeout = 10000; //10 seconds is fair..
			// Setup socket event handlers
			sock.addEventListener(Event.CONNECT, socketConnect);
			sock.addEventListener(ProgressEvent.SOCKET_DATA, socketData);

			try {
				// Connect
				sock.connect(serverAddress, serverPort);
			} catch (e:Error) {
				// Oh shit, there was an error
				trace("##STATS Failed to connect!");

				// Return failure
				return false;
			}
		}
		private function socketConnect(e:Event) {
			// We have connected successfully!
            trace('Connected to the server!');

            // Hook the data connection
            //sock.addEventListener(ProgressEvent.SOCKET_DATA, socketData);
			var buff:ByteArray = new ByteArray();
			writeString(buff, json + '\r\n');
			sock.writeBytes(buff, 0, buff.length);
            sock.flush();
		}
		private function socketData(e:ProgressEvent) {
			trace("Received data, length: "+sock.bytesAvailable);
			var str:String = sock.readUTFBytes(sock.bytesAvailable);
			trace("Received string: "+str);
			try {
				var test = new JSONDecoder(str, false).getValue();
				switch (test["type"]) {
					case "failure":
						trace("###STATS_ACHIEVEMENT WHAT DID YOU JUST DO?!?!?!");
						trace("###STATS_ACHIEVEMENT ERROR: "+test["error"]);
						if (callback != null) {
							callback(false);
						}
						break;
					case "success":
						trace("###STATS_ACHIEVEMENT yay ^.^");
						if (callback != null) {
							callback(true);
						}
						break;
					case "list":
						if (callback != null) {
							callback(test["jsonData"]);
						}
						break;
					default:
						trace("###STATS_ACHIEVEMENT WHY DID I RECEIVE "+test["type"]+"?!?!?!");
						break;
				}
			} catch (error:JSONParseError) {
				trace("HELP ME...");
				trace(str);
			}
		}
		private static function writeString(buff:ByteArray, write:String){
			trace("Message: "+write);
			trace("Length: "+write.length);
            buff.writeUTFBytes(write);
        }
		
		//
		// ACHIVEMENT API
		//
		
		public function ListAchievements(modID:String, callback:Function) {
			this.callback = callback;
			
			var info:Object = {
				type     : "LIST",
				modID    : modID,
				steamID  : SteamID
			};
			
			json = new JSONEncoder(info).getString();
			ServerConnect(SERVER_ADDRESS, SERVER_PORT);
		}
		public function SaveAchievement(modID:String, achievementID:int, achievementValue:int, callback:Function) {
			this.callback = callback;
			
			var info:Object = {
				type    : "SAVE",
				modID   : modID,
				steamID : SteamID,
				achievementID  : achievementID,
				achievementValue : achievementValue
			};
			
			json = new JSONEncoder(info).getString();
			ServerConnect(SERVER_ADDRESS, SERVER_PORT);
		}
	
		
		//
		// Event Handlers 
		//
		public function statCollectSteamID(args:Object) {
			SteamID = args[globals.Players.GetLocalPlayer()];
			trace("STEAM ID: "+SteamID);
		}
		
		public function statAchievementLoad(args:Object) {
			ListAchievements(args.modID, function ( achievementList:Array ):void
			{
				var database:IAchievementDatabase = achievementUI.database;

				gameAPI.SendServerCommand("stat_ach_list_begin");
				database.isLoading = true;

				for each ( var item:Object in achievementList )
				{
					gameAPI.SendServerCommand("stat_ach_list_item " + item.achievementID + " " + item.achievementValue);
					database.setValue(item.achievementID, item.achievementValue);
				}

				gameAPI.SendServerCommand("stat_ach_list_end");
				database.isLoading = false;
			});
		}

		public function statAchievementSend(args:Object) {
			var changeList:Array = achievementUI.database.getChangeList();
			for each ( var item:Object in changeList )
			{
				SaveAchievement( args.modID, item.achievementID, item.achievementValue, null );
			}
		}
    }
}
