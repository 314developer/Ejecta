#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#ifdef __cplusplus
extern "C" {
#endif

void EJFlipPixelsY(GLuint bytesPerRow, GLuint rows, GLubyte * pixels);
void EJPremultiplyAlpha(GLuint width, GLuint height, GLenum format, GLubyte * pixels);

GLfloat * JSValueToGLfloatArray(JSContextRef ctx, JSValueRef value, size_t expectedSize);
GLint * JSValueToGLintArray(JSContextRef ctx, JSValueRef value, size_t expectedSize);
GLuint EJGetBytesPerPixel(GLenum type, GLenum format);

#ifdef __cplusplus
}
#endif