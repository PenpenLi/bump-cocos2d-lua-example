
local shaders = {}

local vertex = [[
    attribute vec4 a_position;
    attribute vec2 a_texCoord;
    attribute vec4 a_color;
    #ifdef GL_ES
    varying lowp vec4 v_fragmentColor;
    varying mediump vec2 v_texCoord;
    #else
    varying vec4 v_fragmentColor;
    varying vec2 v_texCoord;
    #endif
    void main()
    {
        gl_Position = CC_PMatrix * a_position;
        v_fragmentColor = a_color;
        v_texCoord = a_texCoord;
    }
]]

function shaders.roundNode( node,edge )

  local type = tolua.type(node)
  if type ~= 'cc.Sprite' then
    print('**WARNING**: [shaders.roundNode] node should be cc.Sprite, but', type)
    return
  end

  local fragment = [[
  #ifdef GL_ES
  varying lowp vec4 v_fragmentColor;
  varying mediump vec2 v_texCoord;
  #else
  varying vec4 v_fragmentColor;
  varying vec2 v_texCoord;
  #endif

  uniform float u_edge; // 0.1

  void main()
  {
      float edge = u_edge;
      float dis = 0.0;
      vec2 texCoord = v_texCoord;
      if ( texCoord.x < edge )
      {
          if ( texCoord.y < edge )
          {
              dis = distance( texCoord, vec2(edge, edge) );
          }
          if ( texCoord.y > (1.0 - edge) )
          {
              dis = distance( texCoord, vec2(edge, (1.0 - edge)) );
          }
      }
      else if ( texCoord.x > (1.0 - edge) )
      {
          if ( texCoord.y < edge )
          {
              dis = distance( texCoord, vec2((1.0 - edge), edge ) );
          }
          if ( texCoord.y > (1.0 - edge) )
          {
              dis = distance( texCoord, vec2((1.0 - edge), (1.0 - edge) ) );
          }
      }

      if(dis > 0.001)
      {
          float gap = edge * 0.1;
          if(dis <= edge - gap)
          {
              gl_FragColor = texture2D( CC_Texture0,texCoord);
          }
          else if(dis <= edge)
          {
              //gl_FragColor = texture2D( CC_Texture0,texCoord) * (gap - (dis - edge + gap))/gap;
              gl_FragColor = vec4(0,0,0,0);
          }
      }
      else
      {
          gl_FragColor = texture2D( CC_Texture0,texCoord);
      }
  }
  ]]

  local shaderKey = 'shaderRound'
  local glCache = cc.GLProgramCache:getInstance()
  local glProgram = glCache:getGLProgram(shaderKey)
  if not glProgram then
    glProgram = cc.GLProgram:createWithByteArrays(vertex, fragment)
    glProgram:link()
    glProgram:updateUniforms()
    glCache:addGLProgram(glProgram, shaderKey)
  end
  if not glProgram then print('glProgram is nil') return end

  local glProgramState = cc.GLProgramState:getOrCreateWithGLProgram(glProgram)
  if not glProgramState then print('glProgramState is nil') return end

  edge = edge or 0.1
  glProgramState:setUniformFloat('u_edge', 0.1)
  node:setGLProgramState(glProgramState)
end

function shaders.grayNode( node )
  if not node then return end

  -- 片段shader
  local fragment= [[
      #ifdef GL_ES
      precision mediump float;  // shader默认精度为double，openGL为了提升渲染效率将精度设为float
      #endif
      // varying 变量为顶点 shader 经过光栅化阶段的线性插值后传给片段着色器
      varying vec4 v_fragmentColor;  // 颜色
      varying vec2 v_texCoord;       // 坐标
      void main(void)
      {
          // texture2D 方法从采样器中进行纹理采样，得到当前片段的颜色值。CC_Texture0 即为一个采样器
          vec4 c = texture2D(CC_Texture0, v_texCoord);
          // c.rgb即是像素点的三种颜色，dot为点乘，vec3为经验值，可以随意修改
          float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
          // shader的内建变量，表示当前片段的颜色
          gl_FragColor.xyz = vec3(gray);
          // a为透明度
          gl_FragColor.a = c.a;
      }
  ]]
  local pProgram = cc.GLProgram:createWithByteArrays(vertex , fragment)
  -- img为sprite
  node:setGLProgram(pProgram)
end

function shaders.pageCurl(sprite)
  local fragment =
[[
varying vec2 v_texCoord;
uniform sampler2D sourceTex;
uniform sampler2D targetTex;
uniform float time; // Ranges from 0.0 to 1.0

const float MIN_AMOUNT = -0.16;
const float MAX_AMOUNT = 1.3;
float amount = time * (MAX_AMOUNT - MIN_AMOUNT) + MIN_AMOUNT;

const float PI = 3.141592653589793;

const float scale = 512.0;
const float sharpness = 3.0;

float cylinderCenter = amount;
// 360 degrees * amount
float cylinderAngle = 2.0 * PI * amount;

const float cylinderRadius = 1.0 / PI / 2.0;

vec3 hitPoint(float hitAngle, float yc, vec3 point, mat3 rrotation) {
    float hitPoint = hitAngle / (2.0 * PI);
    point.y = hitPoint;
    return rrotation * point;
}


vec4 antiAlias(vec4 color1, vec4 color2, float distance) {
    distance *= scale;
    if (distance < 0.0) return color2;
    if (distance > 2.0) return color1;
    float dd = pow(1.0 - distance / 2.0, sharpness);
    return ((color2 - color1) * dd) + color1;
}

float distanceToEdge(vec3 point) {
    float dx = abs(point.x > 0.5 ? 1.0 - point.x : point.x);
    float dy = abs(point.y > 0.5 ? 1.0 - point.y : point.y);
    if (point.x < 0.0) dx = -point.x;
    if (point.x > 1.0) dx = point.x - 1.0;
    if (point.y < 0.0) dy = -point.y;
    if (point.y > 1.0) dy = point.y - 1.0;
    if ((point.x < 0.0 || point.x > 1.0) && (point.y < 0.0 || point.y > 1.0)) return sqrt(dx * dx + dy * dy);
    return min(dx, dy);
}

vec4 seeThrough(float yc, vec2 p, mat3 rotation, mat3 rrotation) {
    float hitAngle = PI - (acos(yc / cylinderRadius) - cylinderAngle);
    vec3 point = hitPoint(hitAngle, yc, rotation * vec3(p, 1.0), rrotation);

    if (yc <= 0.0 && (point.x < 0.0 || point.y < 0.0 || point.x > 1.0 || point.y > 1.0)) {
        return texture2D(targetTex, v_texCoord);
    }

    if (yc > 0.0) return texture2D(sourceTex, p);

    vec4 color = texture2D(sourceTex, point.xy);
    vec4 tcolor = vec4(0.0);

    return antiAlias(color, tcolor, distanceToEdge(point));
}

vec4 seeThroughWithShadow(float yc, vec2 p, vec3 point, mat3 rotation, mat3 rrotation) {
    float shadow = distanceToEdge(point) * 30.0;
    shadow = (1.0 - shadow) / 3.0;
    if (shadow < 0.0) shadow = 0.0;
    else shadow *= amount;

    vec4 shadowColor = seeThrough(yc, p, rotation, rrotation);
    shadowColor.r -= shadow;
    shadowColor.g -= shadow;
    shadowColor.b -= shadow;
    return shadowColor;
}

vec4 backside(float yc, vec3 point) {
    vec4 color = texture2D(targetTex, point.xy);
    float gray = (color.r + color.b + color.g) / 15.0;
    gray += (8.0 / 10.0) * (pow(1.0 - abs(yc / cylinderRadius), 2.0 / 10.0) / 2.0 + (5.0 / 10.0));
    //color.rgb = vec3(gray);
    return color;
}

vec4 behindSurface(float yc, vec3 point, mat3 rrotation) {
    float shado = (1.0 - ((-cylinderRadius - yc) / amount * 7.0)) / 6.0;
    shado *= 1.0 - abs(point.x - 0.5);

    yc = (-cylinderRadius - cylinderRadius - yc);

    float hitAngle = (acos(yc / cylinderRadius) + cylinderAngle) - PI;
    point = hitPoint(hitAngle, yc, point, rrotation);

    if (yc < 0.0 && point.x >= 0.0 && point.y >= 0.0 && point.x <= 1.0 && point.y <= 1.0 && (hitAngle < PI || amount > 0.5)){
        shado = 1.0 - (sqrt(pow(point.x - 0.5, 2.0) + pow(point.y - 0.5, 2.0)) / (71.0 / 100.0));
        shado *= pow(-yc / cylinderRadius, 3.0);
        shado *= 0.5;
    } else
        shado = 0.0;

    return vec4(texture2D(targetTex, v_texCoord).rgb - shado, 1.0);
}

void main(void) {
    const float angle = 30.0 * PI / 180.0;
    float c = cos(-angle);
    float s = sin(-angle);

    mat3 rotation = mat3(
        c, s, 0,
        -s, c, 0,
        0.12, 0.258, 1
    );

    c = cos(angle);
    s = sin(angle);

    mat3 rrotation = mat3(
        c, s, 0,
        -s, c, 0,
        0.15, -0.5, 1
    );

    vec3 point = rotation * vec3(v_texCoord, 1.0);

    float yc = point.y - cylinderCenter;

    if (yc < - cylinderRadius) {
        // Behind surface
        gl_FragColor = behindSurface(yc, point, rrotation);
        return;
    }

    if (yc > cylinderRadius) {
        // Flat surface
        gl_FragColor = texture2D(sourceTex, v_texCoord);
        return;
    }

    float hitAngle = (acos(yc / cylinderRadius) + cylinderAngle) - PI;

    float hitAngleMod = mod(hitAngle, 2.0 * PI);
    if ((hitAngleMod > PI && amount < 0.5) || (hitAngleMod > PI/2.0 && amount < 0.0)) {
        gl_FragColor = seeThrough(yc, v_texCoord, rotation, rrotation);
        return;
    }

    point = hitPoint(hitAngle, yc, point, rrotation);

    if (point.x < 0.0 || point.y < 0.0 || point.x > 1.0 || point.y > 1.0) {
        gl_FragColor = seeThroughWithShadow(yc, v_texCoord, point, rotation, rrotation);
        //gl_FragColor = vec4(1.0, 0.0, 0.0, 0.1);
        return;
    }

    vec4 color = backside(yc, point);

    vec4 otherColor;
    if (yc < 0.0) {
        float shado = 1.0 - (sqrt(pow(point.x - 0.5, 2.0) + pow(point.y - 0.5, 2.0)) / 0.71);
        shado *= pow(-yc / cylinderRadius, 3.0);
        shado *= 0.5;
        otherColor = vec4(0.0, 0.0, 0.0, shado);
    } else {
        otherColor = texture2D(sourceTex, v_texCoord);
    }

    color = antiAlias(color, otherColor, cylinderRadius - abs(yc));

    vec4 cl = seeThroughWithShadow(yc, v_texCoord, point, rotation, rrotation);
    float dist = distanceToEdge(point);

    gl_FragColor = antiAlias(color, cl, dist);
}
]]

  local shaderKey = 'pageCurl'
  local glCache = cc.GLProgramCache:getInstance()
  local glProgram = glCache:getGLProgram(shaderKey)
  if not glProgram then
    glProgram = cc.GLProgram:createWithByteArrays(vertex, fragment)
    glProgram:link()
    glProgram:updateUniforms()
    glCache:addGLProgram(glProgram, shaderKey)
  end
  if not glProgram then print('glProgram is nil') return end

  local glProgramState = cc.GLProgramState:getOrCreateWithGLProgram(glProgram)
  if not glProgramState then print('glProgramState is nil') return end

  --[[
  local time = 0
  glProgramState:setUniformFloat('time', time)

  local cache = cc.Director:getInstance():getTextureCache()
  glProgramState:setUniformTexture('sourceTex', cache:addImage('/Users/admin/card_back.png'))
  glProgramState:setUniformTexture('targetTex', cache:addImage('/Users/admin/card_fort.png'))
  sprite:setGLProgramState(glProgramState)

  local x = 0.01
  sprite:rotation(90)
  sprite:schedule(function (  )
    if time >= 1.0 then x = -x end
    if time < 0 then x = -x end
    time = time + x
    glProgramState:setUniformFloat('time', time)
  end,1.0/60.0)
  ]]
end

return shaders
