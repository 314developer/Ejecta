#import <Foundation/Foundation.h>

#import <OpenAL/al.h>
#import <OpenAL/alc.h>

@interface EJOpenALBuffer : NSObject {
	unsigned int bufferId;
	ALenum format;
	ALsizei size;
	ALsizei sampleRate;
	
	float duration;
}

- (id)initWithPath:(NSString *)pathp;
- (void*)getAudioDataWithURL:(NSURL *)url;

@property (readonly) unsigned int bufferId;
@property (readonly) float duration;

@end
