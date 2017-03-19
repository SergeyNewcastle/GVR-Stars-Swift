//
//  Shader.fsh
//  StarsSwift
//
//  Created by Newcastle on 19.03.17.
//  Copyright © 2017 Newcastle. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
