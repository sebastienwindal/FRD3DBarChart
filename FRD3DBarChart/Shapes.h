//
//  Shapes.h
//  FRD3DBarChart
//
//  Created by Sebastien Windal on 7/23/12.
//  Copyright (c) 2012 Free Range Developers. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the project's author nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
// TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#ifndef removeme_Shapes_h
#define removeme_Shapes_h

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ
    
    // 6 triangles, 3 square faces
    //right face:
    1.0f, 0.0f, 0.0f,        1.0f, 0.0f, 0.0f,      
    1.0f, 1.0f, 0.0f,         1.0f, 0.0f, 0.0f,     
    1.0f, 0.0f, 1.0f,         1.0f, 0.0f, 0.0f,     
    1.0f, 0.0f, 1.0f,         1.0f, 0.0f, 0.0f,     
    1.0f, 1.0f, 0.0f,         1.0f, 0.0f, 0.0f,     
    1.0f, 1.0f, 1.0f,          1.0f, 0.0f, 0.0f,    
    
    // top face
    1.0f, 1.0f, 0.0f,         0.0f, 1.0f, 0.0f,     
    0.0f, 1.0f, 0.0f,        0.0f, 1.0f, 0.0f,      
    1.0f, 1.0f, 1.0f,          0.0f, 1.0f, 0.0f,    
    1.0f, 1.0f, 1.0f,          0.0f, 1.0f, 0.0f,    
    0.0f, 1.0f, 0.0f,        0.0f, 1.0f, 0.0f,      
    0.0f, 1.0f, 1.0f,         0.0f, 1.0f, 0.0f,     
    
    // left face
    0.0f, 1.0f, 0.0f,        -1.0f, 0.0f, 0.0f,     
    0.0f, 0.0f, 0.0f,       -1.0f, 0.0f, 0.0f,      
    0.0f, 1.0f, 1.0f,         -1.0f, 0.0f, 0.0f,    
    0.0f, 1.0f, 1.0f,         -1.0f, 0.0f, 0.0f,    
    0.0f, 0.0f, 0.0f,       -1.0f, 0.0f, 0.0f,      
    0.0f, 0.0f, 1.0f,        -1.0f, 0.0f, 0.0f,     
    
    /// 
    0.0f, 0.0f, 0.0f,       0.0f, -1.0f, 0.0f,      
    1.0f, 0.0f, 0.0f,        0.0f, -1.0f, 0.0f,     
    0.0f, 0.0f, 1.0f,        0.0f, -1.0f, 0.0f,     
    0.0f, 0.0f, 1.0f,        0.0f, -1.0f, 0.0f,     
    1.0f, 0.0f, 0.0f,        0.0f, -1.0f, 0.0f,     
    1.0f, 0.0f, 1.0f,         0.0f, -1.0f, 0.0f,    
    
    // back
    1.0f, 1.0f, 1.0f,          0.0f, 0.0f, 1.0f,    
    0.0f, 1.0f, 1.0f,         0.0f, 0.0f, 1.0f,     
    1.0f, 0.0f, 1.0f,         0.0f, 0.0f, 1.0f,     
    1.0f, 0.0f, 1.0f,         0.0f, 0.0f, 1.0f,     
    0.0f, 1.0f, 1.0f,         0.0f, 0.0f, 1.0f,     
    0.0f, 0.0f, 1.0f,        0.0f, 0.0f, 1.0f,      
    
    1.0f, 0.0f, 0.0f,        0.0f, 0.0f, -1.0f,     
    0.0f, 0.0f, 0.0f,       0.0f, 0.0f, -1.0f,      
    1.0f, 1.0f, 0.0f,         0.0f, 0.0f, -1.0f,    
    1.0f, 1.0f, 0.0f,         0.0f, 0.0f, -1.0f,    
    0.0f, 0.0f, 0.0f,       0.0f, 0.0f, -1.0f,      
    0.0f, 1.0f, 0.0f,        0.0f, 0.0f, -1.0f,     
};

GLfloat gHLineVertexData[2*6] = 
{
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.0f, -0.0f, -0.0f,       0.0f, +1.0f, 1.0f,    
    1.0f, -0.0f, -0.0f,        0.0f, +1.0f, 1.0f,   
};

GLfloat gVLineVertexData[2*6] = 
{
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.0f, 0.0f, 0.0f,       0.0f, +1.0f, 0.0f,      
    0.0f, 0.0f, 1.0f,        0.0f, +1.0f, 0.0f,     
};


GLfloat gBasePlaneData[6*6] = 
{
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.0f, 0.0f, 0.0f,       0.0f, +1.0f, 0.0f,      
    1.0f, 0.0f, 0.0f,        0.0f, +1.0f, 0.0f,     
    0.0f, 0.0f, 1.0f,        0.0f, +1.0f, 0.0f,     
    0.0f, 0.0f, 1.0f,        0.0f, +1.0f, 0.0f,     
    1.0f, 0.0f, 0.0f,        0.0f, +1.0f, 0.0f,     
    1.0f, 0.0f, 1.0f,         0.0f, +1.0f, 0.0f,    
};

GLfloat gLeftLegendPlaneData[6*8] = 
{
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,  texture X, texture Y
    0.0f, 0.0f, 0.0f,       0.0f, +0.0f, 0.0f,      0.0f, 0.0f,
    3.0f, 0.0f, 0.0f,        0.0f, +0.0f, 0.0f,     1.0f, 0.0f,
    0.0f, 0.0f, 1.0f,        0.0f, +0.0f, 0.0f,     0.0f, 1.0f,
    0.0f, 0.0f, 1.0f,        0.0f, +0.0f, 0.0f,     0.0f, 1.0f,
    3.0f, 0.0f, 0.0f,        0.0f, +0.0f, 0.0f,     1.0f, 0.0f,
    3.0f, 0.0f, 1.0f,         0.0f, +0.0f, 0.0f,    1.0f, 1.0f,
};

GLfloat gTopTextData[6*8] =
{
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,  texture X, texture Y
    0.0f, 0.0f, 0.0f,       0.0f, +0.0f, 0.0f,      0.0f, 0.0f,
    1.0f, 0.0f, 0.0f,        0.0f, +0.0f, 0.0f,     1.0f, 0.0f,
    0.0f, 0.0f, 1.0f,        0.0f, +0.0f, 0.0f,     0.0f, 1.0f,
    0.0f, 0.0f, 1.0f,        0.0f, +0.0f, 0.0f,     0.0f, 1.0f,
    1.0f, 0.0f, 0.0f,        0.0f, +0.0f, 0.0f,     1.0f, 0.0f,
    1.0f, 0.0f, 1.0f,         0.0f, +0.0f, 0.0f,    1.0f, 1.0f,
    

};

#endif
