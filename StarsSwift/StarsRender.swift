
//
//  StarsRender.swift
//  StarsSwift
//
//  Created by Newcastle on 19.03.17.
//  Copyright © 2017 Newcastle. All rights reserved.
//

//import Foundation

func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer? {
     return UnsafeRawPointer(bitPattern: i)
}

enum EngineMode: Int {
     case EngineModeImpulse
     case EngineModeToWarp
     case EngineModeWarp
     case EngineModeToImpulse
}



class StarsRenderer: NSObject, GVRCardboardViewDelegate   {
     
//     private var renderLoop:StarsRenderLoop?;
     
     
     override init() {
          super.init()
     }
     
     var renderLoop: StarsRenderLoop?;
     
     private let VERTEX_COUNT:GLint = 200000
     
     private var _vertices: [GLfloat] = Array(repeating: 0.0,
                                              count: 1200000); //
     private var _offset_position: [GLfloat] = Array(repeating: 0.0, count: 3); //
     private var _offset_velocity: [GLfloat] = Array(repeating: 0.0,
                                              count: 3); //
 
     private var _engine_mode: EngineMode = EngineMode.EngineModeImpulse;
     private var _warp_factor: GLfloat = 0.0;
     private var _last_timestamp: TimeInterval = 0.0;
     
     // Handles to OpenGL variables.
     private var  _shader_program:GLuint = 0;
     private var  _projection_matrix:GLint = 0;
     private var  _eye_from_head_matrix:GLint = 0;
     private var  _head_from_state_matrix:GLint = 0;
     private var  _attrib_position:GLint = 0;
     private var  _attrib_color:GLint = 0;
     private var  _uniform_offset_position:GLint = 0;
     private var  _uniform_offset_velocity:GLint = 0;
     private var  _uniform_warp_factor_vertex:GLfloat = 0;
     private var  _uniform_warp_factor_fragment:GLfloat = 0;
     private var  _uniform_brightness:GLfloat = 0;
     private var  _vertex_buffer:GLuint = 0;
     
     private var vao:GLuint = 0;
    
     
     
     
     
     
     
     
     
     func cardboardView(_ cardboardView: GVRCardboardView!,
                        prepareDrawFrame headTransform: GVRHeadTransform!) {
          
          var timestep:TimeInterval = renderLoop!.nextFrameTime() - _last_timestamp;
          if (timestep > 1.0) {
               timestep = 1.0;
          }
          _last_timestamp = renderLoop!.nextFrameTime();
          //print(_warp_factor);
          //print(timestep);
          
          // Accelerate when our engines are on and we're not in warp mode.
          if (_engine_mode == .EngineModeImpulse || _engine_mode == .EngineModeToWarp) {
               var thrust_vector: [Float] = Array(repeating: 0.0,
                                                  count: 3);
               thrust_vector[0] = 0.0;
               thrust_vector[1] = 0.0;
               thrust_vector[2] = 0.02 * (1.0 + 1000.0 * _warp_factor) * Float(timestep);
               
               
               
               
               var headPoseInStartSpace:GLKMatrix4 = GLKMatrix4Transpose(headTransform.headPoseInStartSpace())
               
               withUnsafePointer(to: &headPoseInStartSpace.m) {
                    $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: headPoseInStartSpace.m)) {
                         glUniformMatrix4fv(_projection_matrix, 1, GLboolean(false), $0)
                         
                         _offset_velocity[0] += thrust_vector[0] * headPoseInStartSpace[0] +
                              thrust_vector[1] * headPoseInStartSpace[4] +
                              thrust_vector[2] * headPoseInStartSpace[8];
                         //print(_offset_velocity[0])
                         _offset_velocity[1] += thrust_vector[0] * headPoseInStartSpace[1] +
                              thrust_vector[1] * headPoseInStartSpace[5] +
                              thrust_vector[2] * headPoseInStartSpace[9];
                         //print(_offset_velocity[1])
                         _offset_velocity[2] += thrust_vector[0] * headPoseInStartSpace[2] +
                              thrust_vector[1] * headPoseInStartSpace[6] +
                              thrust_vector[2] * headPoseInStartSpace[10];
                         //print(_offset_velocity[2])
                    }
               }
               
          }
          
          // Slow down if we're not in warp.
          if (_engine_mode != .EngineModeWarp) {
               let speed:Float = sqrt(
                    _offset_velocity[0] * _offset_velocity[0] +
                    _offset_velocity[1] * _offset_velocity[1] +
                    _offset_velocity[2] * _offset_velocity[2]);
               let max_speed:Float = 0.07 + 5.0 * _warp_factor;
               let drag:Float = 0.995 * (max_speed / fmax(speed, max_speed));
               _offset_velocity[0] *= drag;
               _offset_velocity[1] *= drag;
               _offset_velocity[2] *= drag;
          }
          _offset_position[0] += _offset_velocity[0];
          _offset_position[1] += _offset_velocity[1];
          _offset_position[2] += _offset_velocity[2];
          _offset_position[0] = fmod(_offset_position[0], 200.0);
          _offset_position[1] = fmod(_offset_position[1], 200.0);
          _offset_position[2] = fmod(_offset_position[2], 200.0);
          
          // Adjust our warp factor if needed.
          if (_engine_mode == .EngineModeToWarp) {
               _warp_factor += 0.01;
               if (_warp_factor >= 1.0) {
                    _warp_factor = 1.0;
                    _engine_mode = .EngineModeWarp;
               }
          } else if (_engine_mode == .EngineModeToImpulse) {
               _warp_factor -= 0.01;
               if (_warp_factor <= 0.0) {
                    _warp_factor = 0.0;
                    _engine_mode = .EngineModeImpulse;
               }
          }
          
          glDisable(GLenum(GL_DEPTH_TEST));
          glEnable(GLenum(GL_BLEND));
          glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE));
          glDisable(GLenum(GL_SCISSOR_TEST));
          glClearColor(0.0, 0.0, 0.0, 1.0);
          glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
          glEnable(GLenum(GL_SCISSOR_TEST));

     }
     
    
     func cardboardView(_ cardboardView: GVRCardboardView!, willStartDrawing headTransform: GVRHeadTransform!) {
          
//          if(loadShaders()) {
          loadShaders()
          
          glGenVertexArrays(1, &vao);
          glBindVertexArray(vao);
          
          
          
          _offset_position[0] = 0.0;
          _offset_position[1] = 0.0;
          _offset_position[2] = 0.0;
          _offset_velocity[0] = 0.0;
          _offset_velocity[1] = 0.0;
          _offset_velocity[2] = 0.0;
          _last_timestamp = 0;
          _engine_mode = .EngineModeImpulse;
          _warp_factor = 0.0;
          
          
               //init all attributes locations
               _attrib_position = glGetAttribLocation(_shader_program, "aVertex");
               _attrib_color = glGetAttribLocation(_shader_program, "aColor");
               
               _projection_matrix = glGetUniformLocation(_shader_program, "uClipFromEyeMatrix");
               _eye_from_head_matrix = glGetUniformLocation(_shader_program, "uEyeFromHeadMatrix");
               _head_from_state_matrix = glGetUniformLocation(_shader_program, "uHeadFromStartMatrix");
               _uniform_offset_position = glGetUniformLocation(_shader_program, "uOffsetPosition");
               _uniform_offset_velocity = glGetUniformLocation(_shader_program, "uOffsetVelocity");
               _uniform_warp_factor_vertex = GLfloat(glGetUniformLocation(_shader_program, "uWarpFactorVertex"));
               _uniform_warp_factor_fragment = GLfloat(glGetUniformLocation(_shader_program, "uWarpFactorFragment"));
               _uniform_brightness = GLfloat(glGetUniformLocation(_shader_program, "uBrightness"));
               
               
               
               // Initialize data buffers for vertices. Interlace pos & color.
               var i = 0;
               repeat {
                    
                    let v0 = Float(drand48() * 200.0) - (100.0);
                    let v1 = Float(drand48() * 200.0) - (100.0);
                    let v2 = Float(drand48() * 200.0) - (100.0);
                    
                    _vertices[6 * i + 0] = v0
                    _vertices[6 * i + 1] = v1
                    _vertices[6 * i + 2] = v2
                    
                    _vertices[6 * i + 6] = v0
                    _vertices[6 * i + 7] = v1
                    _vertices[6 * i + 8] = v2
                    
                    
                    //_vertices[6 * i + 0] = Float(drand48() * 200.0) - (100.0);
                    //_vertices[6 * i + 1] = Float(drand48() * 200.0) - (100.0);
                    //_vertices[6 * i + 2] = Float(drand48() * 200.0) - (100.0);
                    
                    //_vertices[6 * i + 6] = Float(drand48() / 200.0) - 100.0;
                    //_vertices[6 * i + 7] = Float(drand48() / 200.0) - 100.0;
                    //_vertices[6 * i + 8] = Float(drand48() / 200.0) - 100.0;
                    
                    _vertices[6 * i + 3] = Float(drand48() / 2.0) + 0.5;
                    _vertices[6 * i + 4] = Float(drand48() / 2.0) + 0.5;
                    _vertices[6 * i + 5] = Float(drand48() / 2.0) + 0.5;
                    _vertices[6 * i +  9] = 0.0;
                    _vertices[6 * i + 10] = 0.0;
                    _vertices[6 * i + 11] = 0.0;
                    i+=2;
               } while i < Int(VERTEX_COUNT)
          
          
             
               glLineWidth(1.0);
               glGenBuffers(1, &_vertex_buffer);
               glBindBuffer(GLenum(GL_ARRAY_BUFFER), _vertex_buffer);
               let totalBufferSize = 6 * VERTEX_COUNT
               glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(totalBufferSize)*4,
                            _vertices, GLenum(GL_STATIC_DRAW));

        
          
          
          // Draw our polygons.
          glBindBuffer(GLenum(GL_ARRAY_BUFFER), _vertex_buffer);
          let size = Int(MemoryLayout<GLfloat>.size) * 6
          
          
          
          
          let pointer0offset = UnsafeRawPointer(bitPattern: 0)
          glVertexAttribPointer(GLuint(_attrib_position),
                                3,
                                GLenum(GL_FLOAT),
                                GLboolean(GL_FALSE),
                                GLsizei(size),
                                pointer0offset);
          
          glEnableVertexAttribArray(GLuint(_attrib_position));
          
          
          
          
          let pointer1offset = UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.stride * 3)
          glVertexAttribPointer(GLuint(_attrib_color),
                                3,
                                GLenum(GL_FLOAT),
                                GLboolean(GL_FALSE),
                                GLsizei(size),
                                pointer1offset);
          
          glEnableVertexAttribArray(GLuint(_attrib_color));
          
          glBindVertexArray(0);

//          }
          
     }
     
     func cardboardView(_ cardboardView: GVRCardboardView!, draw eye: GVREye, with headTransform: GVRHeadTransform!) {
          
          let viewport:CGRect = headTransform.viewport(for: eye);
          glViewport(GLint(viewport.origin.x), GLint(viewport.origin.y), GLsizei(viewport.size.width), GLsizei(viewport.size.height));
          glScissor(GLint(viewport.origin.x), GLint(viewport.origin.y), GLsizei(viewport.size.width), GLsizei(viewport.size.height));
          
          // Get the head matrix.
          var head_from_start_matrix: GLKMatrix4 = headTransform.headPoseInStartSpace()
          
          // Get this eye's matrices.
          var projection_matrix: GLKMatrix4 = headTransform.projectionMatrix(for: eye, near: 0.1, far: 100.0); //projectionMatrixForEye:eye near:0.1f far:100.0f];
          var eye_from_head_matrix: GLKMatrix4 = headTransform.eye(fromHeadMatrix: eye); //eyeFromHeadMatrix:eye];
          
        
          
          glBindVertexArray(vao);
          
          glUseProgram(_shader_program);
          
          // Set the uniform matrix values that will be used by our shader.
          
          withUnsafePointer(to: &projection_matrix.m) {
               $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: projection_matrix.m)) {
                    glUniformMatrix4fv(_projection_matrix, 1, GLboolean(false), $0)
               }
          }
          
          withUnsafePointer(to: &eye_from_head_matrix.m) {
               $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: eye_from_head_matrix.m)) {
                    glUniformMatrix4fv(_eye_from_head_matrix, 1, GLboolean(false), $0)
               }
          }
          
          withUnsafePointer(to: &head_from_start_matrix.m) {
               $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: head_from_start_matrix.m)) {
                    glUniformMatrix4fv(_head_from_state_matrix, 1, GLboolean(false), $0)
               }
          }
          
          
          
          // Set the uniform values that will be used by our shader.
          glUniform3fv(_uniform_offset_position, 1, _offset_position);
          glUniform3fv(_uniform_offset_velocity, 1, _offset_velocity);
          glUniform1f(GLint(_uniform_warp_factor_vertex), _warp_factor);
          glUniform1f(GLint(_uniform_warp_factor_fragment), _warp_factor);
          glUniform1f(GLint(_uniform_brightness), 1.0);
          
          
          
          
          
          
          if (_warp_factor < 0.5) {
               glDrawArrays(GLenum(GL_POINTS), 0, VERTEX_COUNT);
          } else {
               glDrawArrays(GLenum(GL_LINES), 0, VERTEX_COUNT);
          }
          
          glBindVertexArray(0);
          //glDisableVertexAttribArray(GLuint(_attrib_position));
          //glDisableVertexAttribArray(GLuint(_attrib_color));
          
          
     }
     
     
     
     
     func cardboardView(_ cardboardView: GVRCardboardView!, didFire event: GVRUserEvent) {
         
          switch event {
          case .backButton:
               break;
          case .tilt:
               break;
          case .trigger:
               switch (_engine_mode) {
               case .EngineModeImpulse:
                    _engine_mode = .EngineModeToWarp;
                    break
               case .EngineModeToImpulse:
                    _engine_mode = .EngineModeToWarp;
                    break;
                    
               default:
                    _engine_mode = .EngineModeToImpulse;
                    break;
               }
               break;
          }
          
     }
     
     
     func cardboardView(_ cardboardView: GVRCardboardView!, shouldPauseDrawing pause: Bool) {
          renderLoop?.setPaused(pause);
     }
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     // MARK: -  OpenGL ES 2 shader compilation
     
     func loadShaders() -> Bool {
          var vertShader: GLuint = 0
          var fragShader: GLuint = 0
          var vertShaderPathname: String
          var fragShaderPathname: String
          
          // Create shader program.
          _shader_program = glCreateProgram()
          
          // Create and compile vertex shader.
          vertShaderPathname = Bundle.main.path(forResource: "Shader", ofType: "vsh")!
          if self.compileShader(&vertShader, type: GLenum(GL_VERTEX_SHADER), file: vertShaderPathname) == false {
               print("Failed to compile vertex shader")
               return false
          }
          
          // Create and compile fragment shader.
          fragShaderPathname = Bundle.main.path(forResource: "Shader", ofType: "fsh")!
          if self.compileShader(&fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragShaderPathname) == false {
               print("Failed to compile fragment shader")
               return false
          }
          
          // Attach shaders to program.
          glAttachShader(_shader_program, vertShader)
          glAttachShader(_shader_program, fragShader)
          
          // Link program.
          if !self.linkProgram(_shader_program) {
               print("Failed to link program: \(_shader_program)")
               
               if vertShader != 0 {
                    glDeleteShader(vertShader)
                    vertShader = 0
               }
               if fragShader != 0 {
                    glDeleteShader(fragShader)
                    fragShader = 0
               }
               if _shader_program != 0 {
                    glDeleteProgram(_shader_program)
                    _shader_program = 0
               }
               
               return false
          }
          
//          // Get uniform locations.
//          uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_shader_program, "modelViewProjectionMatrix")
//          uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_shader_program, "normalMatrix")
//          
          // Release vertex and fragment shaders.
          if vertShader != 0 {
               glDetachShader(_shader_program, vertShader)
               glDeleteShader(vertShader)
          }
          if fragShader != 0 {
               glDetachShader(_shader_program, fragShader)
               glDeleteShader(fragShader)
          }
          
          return true
     }
     
     
     func compileShader(_ shader: inout GLuint, type: GLenum, file: String) -> Bool {
          var status: GLint = 0
          var source: UnsafePointer<Int8>
          do {
               source = try NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue).utf8String!
          } catch {
               print("Failed to load vertex shader")
               return false
          }
          var castSource: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(source)
          
          shader = glCreateShader(type)
          glShaderSource(shader, 1, &castSource, nil)
          glCompileShader(shader)
          

          var logLength: GLint = 0

          var success:GLint = 0
          glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &success)
          if success != GL_TRUE {
               var logSize:GLint = 0
               glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logSize)
               if logSize != 0 {
                    var infoLog = [GLchar](repeating: 0, count: Int(logSize))
                    glGetShaderInfoLog(shader, logSize, nil, &infoLog)
                    print(String.init(cString: infoLog))
               }
          }
          
          glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
          if status == 0 {
               glDeleteShader(shader)
               return false
          }
          return true
     }
     
     func linkProgram(_ prog: GLuint) -> Bool {
          var status: GLint = 0
          glLinkProgram(prog)
          
          
//             var logLength: GLint = 0
//             glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
//             if logLength > 0 {
//                 var log = UnsafeMutablePointer<GLchar>(malloc(Int(logLength)))
//                 glGetShaderInfoLog(shader, logLength, &logLength, log)
//                 NSLog("Shader compile log: \n%s", "")
//                 free(log)
//             }

          
          glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
          if status == 0 {
               return false
          }
          
          return true
     }
     
     func validateProgram(prog: GLuint) -> Bool {
          var logLength: GLsizei = 0
          var status: GLint = 0
          
          glValidateProgram(prog)
          glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
          if logLength > 0 {
               var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
               glGetProgramInfoLog(prog, logLength, &logLength, &log)
               print("Program validate log: \n\(log)")
          }
          
          glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
          var returnVal = true
          if status == 0 {
               returnVal = false
          }
          return returnVal
     }

}
















