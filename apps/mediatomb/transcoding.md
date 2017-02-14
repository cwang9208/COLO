# Transcoding Content With MediaTomb
## Introduction

MediaTomb version 0.11.0 introduces a new feature - transcoding. It allows you to perform format conversion of your content on the fly allowing you to view media that is otherwise not supported by your player.

For example, you might have your music collection stored in the OGG format, but your player only supports MP3 or you have your movies stored in DivX format, but your player only supports MPEG2 and MPEG4.

## Theory Of Operation

### What Happens On The User Level

So how does this work? First, let's look at the normal situation where you are playing content that is natively supported by your player, let's say a DivX movie. You add it to the server, browse the content on your device, hit play and start streaming the content. Content that the player can not handle is usually grayed out in the on screen display or marked as unsupported.

Now, what happens if transcoding is in place?

First, you define transcoding profiles, specifying which formats should be converted, let's assume that you have some music stored in the FLAC format, but your device only supports MP3 and WAV. So, you can define that all FLAC media should be transcoded to WAV. You then start MediaTomb and browse the content as usual on your device, if everything was set up correctly you should see that your FLAC files are marked as  playable now. You hit play, just like usual, and you will see that your device starts playback.

Here is what happens in the background: when you browse MediaTomb, we will look at the transcoding profile that you specified and, assuming the example above, tell your player that each FLAC file is actually a WAV file. Remember, we assumed that the player is capable of playing WAV content, so it will display the items as playable. As soon as you press  play, we will use the options defined in the transcoding profile to launch the transcoder, we will feed it the original FLAC file and serve the transcoded WAV output directly to your player. The transcoding is done on the fly, the files are not stored on disk and do not require additional disk space.

### Technical Background
The current implementation allows to plug in any application to do the transcoding. The only important thing is, that the application is capable of writing the output to a FIFO.

The application can be any executable and is launched as a process with a set of given parameters that are defined in the profile configuration. The special command line tokes %in and %out that are used in the profile will be substituted by the input file name or input URL and the output FIFO name.

So, the parameters tell the transcoding application: read content from this file, transcode it, and write the output to this FIFO. MediaTomb will read the output from the FIFO and serve the transcoded stream to the player device.

## Sample Configuration

### Profile Selection

What do we want to transcode? Let's assume that you have some .flv files on your drive or that you want to watch YouTube videos on your device using MediaTomb. I have not yet heard of a UPnP player device that natively supports flash video, so let's tell MediaTomb what we want to transcode all .flv content to something that our device understands.

This can be done in the mimetype-profile section under transcoding, mappings:
```
<transcode mimetype="video/x-flv" using="vlcprof"/>
```

So, we told MediaTomb to transcode all video/x-flv content using the profile named "vlcprof".

### Profile Definition
We define vlcprof in the profiles section:
```
<profile name="vlcprof" enabled="yes" type="external">
  <mimetype>video/mpeg</mimetype>
  <agent command="vlc" arguments="-I dummy %in --sout #transcode{venc=ffmpeg,vcodec=mp2v,vb=4096,fps=25,aenc=ffmpeg,acodec=mpga,ab=192,samplerate=44100,channels=2}:standard{access=file,mux=ps,dst=%out} vlc:quit"/>
  <buffer size="10485760" chunk-size="131072" fill-size="2621440"/>
  <accept-url>yes</accept-url>
  <first-resource>yes</first-resource>
</profile>
```
Let's have a closer look:
```
<profile name="vlcprof" enabled="yes" type="external">
```

The profile tag defines the name of the profile - in our example it's "vlcprof", it allows you to quickly switch the profile on and off by setting the enabled parameter to "yes" or "no".

#### Choosing The Transcoder

Now it is time to look at the agent parameter - this tells us which application to execute and it also provides the necessary command line options for it:
```
<agent command="vlc" arguments="-I dummy %in --sout #transcode{venc=ffmpeg,vcodec=mp2v,vb=4096,fps=25,aenc=ffmpeg,acodec=mpga,ab=192,samplerate=44100,channels=2}:standard{access=file,mux=ps,dst=%out} vlc:quit"/>
```
In the above example the command to be executed is "vlc, it will be called with parameter specified in the arguments attribute. Note the special *%in* and *%out* tokens - they are not part of the vlc command line but have a special meaning in MediaTomb. The *%in* token will be replaced by the input file name (i.e. the file that needs to be transcoded) and the *%out* token will be replaced by the output FIFO name, from where the transcoded content will be read by MediaTomb and sent to the player.

Just to make it clearer:
```
<agent command="executable name" arguments="command line %in %out/>
```
So, an agent tag defines the command which is an executable, and arguments which are the command line options and where *%in* and *%out* tokens are used in the place of the input and output file names.
