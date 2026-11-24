package ch.brainclash.brain_clash

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var pool: SoundPool? = null
    private var music: MediaPlayer? = null
    private val sounds = mutableMapOf<String,Int>()
    private val ready = mutableSetOf<Int>()
    private var musicEnabled = false
    private var active = false
    private var musicVolume = 0.2f
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pool = SoundPool.Builder().setMaxStreams(4).setAudioAttributes(
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME)
              .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()).build()
        pool?.setOnLoadCompleteListener { _, id, status -> if(status == 0) ready.add(id) }
        val resourcesByName = mapOf(
            "right" to R.raw.bc_right, "wrong" to R.raw.bc_wrong,
            "streak" to R.raw.bc_streak, "energy" to R.raw.bc_energy,
            "countdown" to R.raw.bc_countdown, "start" to R.raw.bc_start,
            "win" to R.raw.bc_win, "loss" to R.raw.bc_loss, "draw" to R.raw.bc_draw,
            "unlock" to R.raw.bc_unlock, "menu" to R.raw.bc_menu)
        for((name,id) in resourcesByName) sounds[name] = pool?.load(this,id,1) ?: 0
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"brainclash/audio").setMethodCallHandler { call, result ->
            val vol = (call.argument<Number>("volume")?.toFloat() ?: .65f).coerceIn(0f,1f)
            when(call.method) {
                "effect" -> {
                    val id=sounds[call.argument<String>("name")]
                    if(id!=null && ready.contains(id) && active) pool?.play(id,vol,vol,1,0,1f)
                    result.success(null)
                }
                "music" -> {
                    musicEnabled=call.argument<Boolean>("enabled") ?: false
                    musicVolume=vol
                    updateMusic()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun updateMusic() {
        if(musicEnabled && active) {
            if(music==null) music=MediaPlayer.create(this,R.raw.bc_music)?.apply { isLooping=true }
            music?.setVolume(musicVolume,musicVolume)
            music?.start()
        } else if(music?.isPlaying==true) music?.pause()
    }
    override fun onResume(){super.onResume();active=true;updateMusic()}
    override fun onPause(){active=false;updateMusic();super.onPause()}
    override fun onDestroy(){music?.release();music=null;pool?.release();pool=null;ready.clear();super.onDestroy()}
}
