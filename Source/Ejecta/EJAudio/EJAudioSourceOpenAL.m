#import "EJAudioSourceOpenAL.h"
#import "EJApp.h"

@implementation EJAudioSourceOpenAL

@synthesize delegate;

- (id)initWithPath:(NSString *)pathp {
	if( self = [super init] ) {
		path = [pathp retain];
		
		buffer = [[EJApp instance].openALManager.buffers objectForKey:path];
		if( buffer ) {
			[buffer retain];
		}
		else {
			buffer = [[EJOpenALBuffer alloc] initWithPath:path];
			[[EJApp instance].openALManager.buffers setObject:buffer forKey:path];
		}
		
		alGenSources(1, &sourceId); 
		alSourcei(sourceId, AL_BUFFER, buffer.bufferId);
		alSourcef(sourceId, AL_PITCH, 1.0f);
		alSourcef(sourceId, AL_GAIN, 1.0f);
	}
	return self;
}

- (void)dealloc {
	if( sourceId ) {
		alDeleteSources(1, &sourceId);
	}
	
	// If the retainCount is 2, only this instance and the .buffers dictionary
	// still retain the source - so remove it from the dict and delete it completely
	if( buffer.retainCount == 2 ) {
		[[EJApp instance].openALManager.buffers removeObjectForKey:path];
	}
	[buffer release];
	[path release];
	[endTimer invalidate];
	
	[super dealloc];
}

- (void)play {
	alSourcePlay( sourceId );
	
	[endTimer invalidate];
	
	float targetTime = buffer.duration - self.currentTime;
	endTimer = [NSTimer scheduledTimerWithTimeInterval:targetTime
		target:self selector:@selector(ended:) userInfo:nil repeats:NO];
}

- (void)pause {
	alSourceStop( sourceId );
	[endTimer invalidate];
	endTimer = nil;
}

- (void)setLooping:(BOOL)loop {
	looping = loop;
	alSourcei( sourceId, AL_LOOPING, loop ? AL_TRUE : AL_FALSE );
}

- (void)setVolume:(float)volume {
	alSourcef( sourceId, AL_GAIN, volume );
}

- (float)currentTime {
	float time;
	alGetSourcef( sourceId, AL_SEC_OFFSET,  &time );
	return time;
}

- (void)setCurrentTime:(float)time {
	alSourcef( sourceId, AL_SEC_OFFSET,  time );
}

- (float)duration {
	return buffer.duration;
}

- (void)ended:(NSTimer *)timer {
	endTimer = nil;
	if( !looping ) {
		[delegate sourceDidFinishPlaying:self];
	}
}

@end
