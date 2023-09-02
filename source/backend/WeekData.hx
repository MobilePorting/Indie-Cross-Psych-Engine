package backend;

import states.FreeplaySelectState;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;

	var hideBonus:Bool;
	var hideNightmare:Bool;
}

class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];

	public var folder:String = '';

	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var freeplayColor:Array<Int>;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;

	public var hideBonus:Bool;
	public var hideNightmare:Bool;

	public var fileName:String;

	public static function createWeekFile():WeekFile
	{
		var weekFile:WeekFile = {
			songs: [
				["Bopeebo", "dad", [146, 113, 253]],
				["Fresh", "dad", [146, 113, 253]],
				["Dad Battle", "dad", [146, 113, 253]]
			],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			freeplayColor: [146, 113, 253],
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: '',

			hideBonus: true,
			hideNightmare: true
		};
		return weekFile;
	}

	public function new(weekFile:WeekFile, fileName:String)
	{
		songs = weekFile.songs;
		weekCharacters = weekFile.weekCharacters;
		weekBackground = weekFile.weekBackground;
		weekBefore = weekFile.weekBefore;
		storyName = weekFile.storyName;
		weekName = weekFile.weekName;
		freeplayColor = weekFile.freeplayColor;
		startUnlocked = weekFile.startUnlocked;
		hiddenUntilUnlocked = weekFile.hiddenUntilUnlocked;
		hideStoryMode = weekFile.hideStoryMode;
		hideFreeplay = weekFile.hideFreeplay;
		difficulties = weekFile.difficulties;

		hideBonus = weekFile.hideBonus;
		hideNightmare = weekFile.hideNightmare;

		this.fileName = fileName;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false)
		{
			weeksList = [];
			weeksLoaded.clear();
			#if MODS_ALLOWED
			var directories:Array<String> = [Paths.mods(), SUtil.getPath() + Paths.getPreloadPath()];
			var originalLength:Int = directories.length;
	
			for (mod in Mods.parseList().enabled)
				directories.push(Paths.mods(mod + '/'));
			#else
			var directories:Array<String> = [SUtil.getPath() + Paths.getPreloadPath()];
			var originalLength:Int = directories.length;
			#end
	
			var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));
			for (i in 0...sexList.length) {
				for (j in 0...directories.length) {
					var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
					if(!weeksLoaded.exists(sexList[i])) {
						var week:WeekFile = getWeekFile(fileToCheck);
						if(week != null) {
							var weekFile:WeekData = new WeekData(week, sexList[i]);
	
							#if MODS_ALLOWED
							if(j >= originalLength) {
								weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length-1);
							}
							#end
	
							if(weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay && FreeplaySelectState.curSelected == 0) || (!isStoryMode && !weekFile.hideBonus && FreeplaySelectState.curSelected == 1) || (!isStoryMode && !weekFile.hideNightmare && FreeplaySelectState.curSelected == 2))) {
								weeksLoaded.set(sexList[i], weekFile);
								weeksList.push(sexList[i]);
							}
						}
					}
				}
			}
	
			#if MODS_ALLOWED
			for (i in 0...directories.length) {
				var directory:String = directories[i] + 'weeks/';
				if(FileSystem.exists(directory)) {
					var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
					for (daWeek in listOfWeeks)
					{
						var path:String = directory + daWeek + '.json';
						if(sys.FileSystem.exists(path))
						{
							addWeek(daWeek, path, directories[i], i, originalLength);
						}
					}
	
					for (file in FileSystem.readDirectory(directory))
					{
						var path = haxe.io.Path.join([directory, file]);
						if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
						{
							addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
						}
					}
				}
			}
			#end
		}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if (!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if (week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if (i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
					#end
				}
				if ((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay && FreeplaySelectState.curSelected == 0) || (!PlayState.isStoryMode && !weekFile.hideBonus && FreeplaySelectState.curSelected == 1) || (!PlayState.isStoryMode && !weekFile.hideNightmare && FreeplaySelectState.curSelected == 2))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile
	{
		var rawJson:String = null;
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
			rawJson = File.getContent(path);
		#else
		if (OpenFlAssets.exists(path))
			rawJson = Assets.getText(path);
		#end

		if (rawJson != null && rawJson.length > 0)
		{
			return cast Json.parse(rawJson);
		}
		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE
	// To use on PlayState.hx or Highscore stuff
	inline public static function getWeekFileName():String
		return weeksList[PlayState.storyWeek];

	// Used on LoadingState, nothing really too relevant
	inline public static function getCurrentWeek():WeekData
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);

	public static function setDirectoryFromWeek(?data:WeekData = null)
	{
		Mods.currentModDirectory = '';
		if (data != null && data.folder != null && data.folder.length > 0)
			Mods.currentModDirectory = data.folder;
	}

	public static function loadTheFirstEnabledMod()
	{
		Mods.currentModDirectory = '';

		#if MODS_ALLOWED
		if (FileSystem.exists("modsList.txt"))
		{
			var list:Array<String> = CoolUtil.listFromString(File.getContent(SUtil.getPath() + "modsList.txt"));
			var foundTheTop = false;
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1" && !foundTheTop)
				{
					foundTheTop = true;
					Mods.currentModDirectory = dat[0];
				}
			}
		}
		#end
	}
}