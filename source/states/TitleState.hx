package states;

import flixel.system.FlxSplash;
import backend.ClientPrefs;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
#if sys
import sys.thread.Thread;
#end
#if VIDEOS_ALLOWED
import backend.VideoSpriteManager;
#end
using StringTools;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var resizeConstant:Float = 1.196;
	var wackyImage:FlxSprite;
	var mustUpdate:Bool = false;

	public static var updateVersion:String = '';

	#if VIDEOS_ALLOWED private var video:VideoSpriteManager; #end

	public static var watched:Bool = false;

	var skipText:FlxText;

	override public function create():Void
	{
		#if !(debug) // debug skips the splash for some reason
		if(FlxSplash.icBG != null){
		FlxTween.tween(FlxSplash.icBG, {alpha: 0}, 0.6, {ease: FlxEase.quadOut, onComplete: function(Tween:FlxTween){
				FlxG.stage.removeChild(FlxSplash.icBG);
			}
		});
	}
		#end
		#if mobile
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 30;
		FlxG.keys.preventDefaultKeys = [TAB];
		// DEBUG BULLSHIT
		super.create();
		backend.Highscore.load();

		if (!initialized)
		{
			if (FlxG.save.data != null)
			{
				if (FlxG.save.data.fullscreen)
				{
					FlxG.fullscreen = FlxG.save.data.fullscreen;
					// trace('LOADED FULLSCREEN SETTING!!');
				}
				if (FlxG.save.data.canSkip == null)
					FlxG.save.data.canSkip = false;
				FlxG.save.flush();
			}
		}
		persistentUpdate = true;
		persistentDraw = true;

		/*if (FlxG.save.data.weekCompleted != null)
			{
				StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}*/

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			#if mobileC controls.isInSubstate = false; #end // idfk what's wrong
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
		{
			startIntro();
			#if VIDEOS_ALLOWED
			if (!watched)
			{
				#if sys
				Thread.create(() -> // faster video loading?
				{
				#end
				video = new VideoSpriteManager();
				video.startVideo(Paths.video('intro'));
				add(video);
				video.setFinishCallBack(videoCallBack);
				#if sys
				});
				#end

				skipText = new FlxText(0, FlxG.height - 26, 0, #if (desktop && !hl) "Press Escape To Skip" #elseif android "Press Back On Your Phone To Skip" #end, 18);
				skipText.alpha = 0;
				skipText.setFormat(Paths.font('Bronx.otf'), 18, FlxColor.WHITE, RIGHT);
				skipText.scrollFactor.set();
				skipText.screenCenter(X);
				add(skipText);
				if (FlxG.save.data.canSkip)
				{
					FlxTween.tween(skipText, {alpha: 1}, 1, {ease: FlxEase.quadIn});
					FlxTween.tween(skipText, {alpha: 0}, 1, {ease: FlxEase.quadIn, startDelay: 4});
				}
			}
			#else
			videoCallBack();
			#end
		}
		#end
	}

	var logoBl:FlxSprite;
	var bfDance:FlxSprite;
	var danceLeft:Bool = false;
	var Play:FlxSprite;
	var titleText:FlxSprite;
	var bendy:FlxSprite;
	var cup:FlxSprite;
	var sans:FlxSprite;
	var indieBG:FlxSprite;

	function startIntro()
	{
		if (!initialized)
		{
			if (FlxG.sound.music == null)
			{
				// FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				// FlxG.sound.music.fadeIn(4, 0, 0.7);
			}
		}

		Conductor.bpm = 117;
		persistentUpdate = true;
		indieBG = new FlxSprite();
		indieBG.frames = Paths.getSparrowAtlas('title/Bg');
		indieBG.antialiasing = ClientPrefs.data.antialiasing;
		indieBG.animation.addByPrefix('bump', 'ddddd', 24, false);
		indieBG.animation.play('bump', true);
		indieBG.updateHitbox();
		indieBG.screenCenter();
		add(indieBG);
		cup = new FlxSprite().loadGraphic(Paths.image('title/CupCircle'));
		cup.setGraphicSize(Std.int(cup.width / resizeConstant));
		cup.antialiasing = ClientPrefs.data.antialiasing;
		cup.blend = ADD;
		cup.updateHitbox();
		cup.screenCenter();
		add(cup);
		cup.x -= 300;
		FlxTween.tween(cup, {angle: 360}, 8, {type: FlxTweenType.LOOPING});

		sans = new FlxSprite().loadGraphic(Paths.image('title/SansCircle'));
		sans.setGraphicSize(Std.int(sans.width / resizeConstant));
		sans.antialiasing = ClientPrefs.data.antialiasing;
		sans.blend = ADD;
		sans.updateHitbox();
		sans.screenCenter();
		add(sans);
		FlxTween.tween(sans, {angle: -360}, 8, {type: FlxTweenType.LOOPING});
		sans.y -= 170;

		logoBl = new FlxSprite();
		logoBl.frames = Paths.getSparrowAtlas('title/Logo');
		logoBl.setGraphicSize(Std.int(logoBl.width / resizeConstant));
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBl.animation.addByPrefix('bump', 'Tween 11', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		logoBl.screenCenter();
		logoBl.blend = ADD;
		logoBl.x -= 285;
		logoBl.y -= 25;

		titleText = new FlxSprite(660, 570);
		titleText.frames = Paths.getSparrowAtlas('title/Playbutton');
		titleText.animation.addByPrefix('idle', "Button", 24, true);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		titleText.animation.play('idle', true);
		titleText.setGraphicSize(Std.int(titleText.width / 1.1));
		titleText.updateHitbox();
		titleText.blend = ADD;
		add(titleText);

		Play = new FlxSprite(titleText.x + 30, titleText.y + 5);
		Play.frames = Paths.getSparrowAtlas('title/PlayText');
		Play.antialiasing = ClientPrefs.data.antialiasing;
		Play.animation.addByPrefix('bump', 'c', 24, false);
		Play.animation.play('bump');
		Play.setGraphicSize(Std.int(Play.width / 1.1));
		add(Play);

		bendy = new FlxSprite().loadGraphic(Paths.image('title/BendyCircle'));
		bendy.setGraphicSize(Std.int(bendy.width / resizeConstant));
		bendy.antialiasing = ClientPrefs.data.antialiasing;
		bendy.blend = ADD;
		bendy.updateHitbox();
		add(bendy);
		FlxTween.tween(bendy, {angle: 360}, 8, {type: FlxTweenType.LOOPING});
		bendy.x += 595;
		bendy.y += 50;

		bfDance = new FlxSprite(690, 180);
		bfDance.frames = Paths.getSparrowAtlas('title/BF');
		bfDance.animation.addByPrefix('bop', 'BF idle dance', 24, false);
		bfDance.antialiasing = ClientPrefs.data.antialiasing;
		bfDance.blend = ADD;
		add(bfDance);
		add(logoBl);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.screenCenter();
		logo.antialiasing = ClientPrefs.data.antialiasing;
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(blackScreen);
		if (watched)
			blackScreen.alpha = 0;
		skipIntro();
	}

	var transitioning:Bool = false;

	private static var playJingle:Bool = false;

	override function update(elapsed:Float)
	{
		#if VIDEOS_ALLOWED
		if(FlxG.save.data.canSkip && FlxG.keys.justReleased.ESCAPE #if android || FlxG.android.justReleased.ANY #end)
			videoCallBack();
		#end

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		if (FlxG.mouse.justReleased)
			pressedEnter = true;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (pressedEnter && watched)
			{
				flash(FlxColor.WHITE, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;

				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					if (mustUpdate)
					{
						MusicBeatState.switchState(new OutdatedState());
					}
					else
					{
						MusicBeatState.switchState(new MainMenuState());
					}
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		super.update(elapsed);
	}

	private var sickBeats:Int = 0; // Basically curBeat but won't be skipped if you hold the tab or resize the screen

	public static var closedState:Bool = false;

	override function beatHit()
	{
		super.beatHit();
			logoBl.animation.play('bump', true);
			bfDance.animation.play('bop', true);
			indieBG.animation.play('bump', true);

		if (!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					skipIntro(); // idfk im so dumb i think thats the only way to get rid of intro textyy
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;

	function skipIntro():Void
	{
		skippedIntro = true;
	}

	function flash(color:FlxColor, duration:Float)
	{
		FlxG.camera.stopFX();
		FlxG.camera.flash(color, duration);
	}

	public function videoCallBack()
	{
		#if VIDEOS_ALLOWED
		video.destroy();
		#end
		FlxG.save.data.canSkip = true;
		FlxG.save.flush();
		FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		FlxG.sound.music.fadeIn(4, 0, 1);
		FlxTween.tween(blackScreen, {alpha: 0}, 0.8, {ease: FlxEase.quadInOut});
		initialized = true;
		skippedIntro = true;
		transitioning = false;
		watched = true;
		skipText.visible = false;
		trace('video ended');
	}
}
