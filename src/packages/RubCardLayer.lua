-- date:2017/9/26
-- author:looyer
-- purpose:3D搓牌效果层,
-- https://my.oschina.net/u/146803/blog/1544311

local FrameCache = cc.SpriteFrameCache:getInstance()

-- 顶点着色器
local strVertSource =
[[
attribute vec4 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;

uniform float ratio; //牌初始状态到搓牌最终位置的完成度比例
uniform float radius; //搓牌类似于绕圆柱滚起，其圆柱的半径
uniform float width;
uniform float finish; //是否完成搓牌

uniform float offx;
uniform float offy;

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
    //注意OpenGL-ES中：1.attribute修饰的变量是常量。2.没有自动转类型float a = 1;或者5.0/3都是错误的
    //这两个问题改了两天，可以通过修改CPP代码，打印log来调试cocos2dx程序
    vec4 tmp_pos = a_position;

    //顺时针旋转90度
    tmp_pos = vec4(tmp_pos.y, -tmp_pos.x, tmp_pos.z, tmp_pos.w);

    if(finish > 0.5) {
        tmp_pos = vec4(tmp_pos.x, -width - tmp_pos.y, tmp_pos.z, tmp_pos.w);

    }else {
        //计算卡牌弯曲的位置，类似于卡牌绕圆柱卷起的原理
        float halfPeri = radius * 3.14159; //半周长
        float hr = halfPeri * ratio;
        if(tmp_pos.y < -width + hr) {
            float dy = -tmp_pos.y - (width - hr);
            float arc = dy/radius;
            tmp_pos.y = -width + hr - sin(arc)*radius;
            tmp_pos.z = radius * (1.0-cos(arc)); //注意之前这里是1，是错误的，opengles不自动类型转换
        }
    }



    tmp_pos += vec4(offx, offy, 0.0, 0.0);

    gl_Position = CC_MVPMatrix * tmp_pos;
    v_fragmentColor = a_color;
    v_texCoord = a_texCoord;
}
]]

-- 片段着色器
local strFragSource =
[[
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
    //TODO, 这里可以做些片段着色特效

    gl_FragColor = texture2D(CC_Texture0, v_texCoord);
}
]]

-- 通过图片取得纹理id，和该纹理在plist图中的纹理坐标范围
local function getTextureAndRange(szImage)

    local sprite = FrameCache:getSpriteFrame(szImage)

    local rect = sprite:getRect()
    local tex = sprite:getTexture()
    local id = tex:getName() --纹理ID
    local bigWide = tex:getPixelsWide() --plist图集的宽度
    local bigHigh = tex:getPixelsHigh()

    -- 左右上下的纹理范围
    local ll, rr, tt, bb = rect.x/bigWide, (rect.x + rect.width)/bigWide, rect.y/bigHigh, (rect.y + rect.height)/bigHigh
    return id, {ll, rr, tt, bb}, {rect.width, rect.height}
end

-- 创建3D牌面，所需的顶点和纹理数据, size:宽高, texRange:纹理范围, bFront:是否正面
local function initCardVertex(size, texRange, bFront)
    local nDiv = 100 --将宽分成100份

    dump(size, 'size')
    dump(texRange, 'texRange')

    local verts = {} --位置坐标
    local texs = {} --纹理坐标
    local dh = size.height
    local dw = size.width/nDiv

    --计算顶点位置
    for c = 1, nDiv do
        local x, y = (c-1)*dw, 0
        local quad = {}
        if bFront then
            quad = {x, y, x+dw, y, x, y+dh, x+dw, y, x+dw, y+dh, x, y+dh}
        else
            quad = {x, y, x, y+dh, x+dw, y, x+dw, y, x, y+dh, x+dw, y+dh}
        end
        for _, v in ipairs(quad) do table.insert(verts, v) end
    end

    local bXTex = true --是否当前在计算横坐标纹理坐标，
    for _, v in ipairs(verts) do
        if bXTex then
            if bFront then
                table.insert(texs, v/size.width * (texRange[2] - texRange[1]) + texRange[1])
            else
                table.insert(texs, v/size.width * (texRange[1] - texRange[2]) + texRange[2])
            end
        else
            if bFront then
                table.insert(texs, (1-v/size.height) * (texRange[4] - texRange[3]) + texRange[3])
            else
                table.insert(texs, v/size.height * (texRange[3] - texRange[4]) + texRange[4])
            end
        end
        bXTex = not bXTex
    end

    local res = {}
    local tmp = {verts, texs}
    for _, v in ipairs(tmp) do
        local buffid = gl.createBuffer()
        gl.bindBuffer(gl.ARRAY_BUFFER, buffid)
        gl.bufferData(gl.ARRAY_BUFFER, table.getn(v), v, gl.STATIC_DRAW)
        gl.bindBuffer(gl.ARRAY_BUFFER, 0)
        table.insert(res, buffid)
    end
    return res, #verts
end

-- 创建搓牌效果层, pList:图片合集.plist文件, szBack:牌背面图片名, szFont:牌正面图片名, 注意：默认传入的牌在plist文件中是竖直的, scale缩放比
local function createRubCardEffectLayer(pList, szBack, szFont, scale)
    scale = scale or 1.0

    --预加载pList图集(注重复添加没关系，只会保存一份)
    FrameCache:addSpriteFrames(pList)

    -- 取得屏幕宽高
    local Director = cc.Director:getInstance()
    local WinSize = Director:getWinSize()

    -- 创建广角60度，视口宽高比是屏幕宽高比，近平面1.0，远平面1000.0，的视景体
    local camera = cc.Camera:createPerspective(45, WinSize.width/WinSize.height, 1, 1000)
    camera:setCameraFlag(cc.CameraFlag.USER2)
    --设置摄像机的绘制顺序，越大的深度越绘制的靠上，所以默认摄像机默认是0，其他摄像机默认是1, 这句很重要！！
    camera:setDepth(1)
    camera:setPosition3D(cc.vec3(0, 0, 800))
    camera:lookAt(cc.vec3(0, 0, 0), cc.vec3(0, 1, 0))

    -- 创建用于OpenGL绘制的节点
    local glNode = gl.glNodeCreate()
    local glProgram = cc.GLProgram:createWithByteArrays(strVertSource, strFragSource)
    glProgram:retain()
    glProgram:updateUniforms()

    -- 创建搓牌图层
    local layer = cc.Layer:create()
    layer:setCameraMask(cc.CameraFlag.USER2)
    layer:addChild(glNode)
    layer:addChild(camera)

    -- 退出时，释放glProgram程序
    local function onNodeEvent(event)
        if "exit" == event then
            glProgram:release()
        end
    end
    layer:registerScriptHandler(onNodeEvent)

    local posNow = cc.p(0, 0)
    --创建触摸回调
    local function touchBegin(touch, event)
        posNow = touch:getLocation()
        return true
    end
    local function touchMove(touch, event)
        local location = touch:getLocation()
        local dy = location.y - posNow.y

        layer.ratioVal = cc.clampf(layer.ratioVal + dy/100, 0.0, 0.9) --最大程度默认0.9
        posNow = location
        return true
    end
    local function touchEnd(touch, event)
        layer.ratioVal = 0.0
        return true
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(touchBegin, cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(touchMove, cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(touchEnd, cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = layer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)

    --创建牌的背面
    local id1, texRange1, sz1 = getTextureAndRange(szBack)
    local msh1, nVerts1 = initCardVertex(cc.size(sz1[1] * scale, sz1[2] * scale), texRange1, true)
    --创建牌的正面
    local id2, texRange2, sz2 = getTextureAndRange(szFont)
    local msh2, nVerts2 = initCardVertex(cc.size(sz2[1] * scale, sz2[2] * scale), texRange2, false)

    --搓牌的程度控制， 搓牌类似于通过一个圆柱滚动将牌粘着起来的效果。下面的参数就是滚动程度和圆柱半径
    layer.ratioVal = 0.0
    layer.radiusVal = sz1[1]*scale/math.pi;
    dump(layer.radiusVal)

    --牌的渲染信息
    local cardMesh = {
                        {id1, msh1, nVerts1},
                        {id2, msh2, nVerts2},
                    }
    -- OpenGL绘制函数
    local function draw(transform, transformUpdated)
        gl.enable(gl.CULL_FACE)
        glProgram:use()
        glProgram:setUniformsForBuiltins()

        for _, v in ipairs(cardMesh) do

            gl.bindTexture(gl.TEXTURE_2D, v[1])

            -- 传入搓牌程度到着色器中，进行位置计算
            local ratio = gl.getUniformLocation(glProgram:getProgram(), "ratio")
            glProgram:setUniformLocationF32(ratio, layer.ratioVal)
            local radius = gl.getUniformLocation(glProgram:getProgram(), "radius")
            glProgram:setUniformLocationF32(radius, layer.radiusVal)


            -- 偏移牌，使得居中
            local offx = gl.getUniformLocation(glProgram:getProgram(), "offx")
            glProgram:setUniformLocationF32(offx, WinSize.width/2 - sz1[2]/2*scale)
            local offy = gl.getUniformLocation(glProgram:getProgram(), "offy")
            glProgram:setUniformLocationF32(offy, WinSize.height/2 + sz1[1]/2*scale)


            local width = gl.getUniformLocation(glProgram:getProgram(), "width")
            glProgram:setUniformLocationF32(width, sz1[1]*scale)


            gl.glEnableVertexAttribs(bit._or(cc.VERTEX_ATTRIB_FLAG_TEX_COORDS, cc.VERTEX_ATTRIB_FLAG_POSITION))
            gl.bindBuffer(gl.ARRAY_BUFFER, v[2][1])
            gl.vertexAttribPointer(cc.VERTEX_ATTRIB_POSITION,2,gl.FLOAT,false,0,0)
            gl.bindBuffer(gl.ARRAY_BUFFER, v[2][2])
            gl.vertexAttribPointer(cc.VERTEX_ATTRIB_TEX_COORD,2,gl.FLOAT,false,0,0)
            gl.drawArrays(gl.TRIANGLES, 0, v[3])
        end
        gl.bindTexture(gl.TEXTURE_2D, 0)
        gl.bindBuffer(gl.ARRAY_BUFFER, 0)
    end
    glNode:registerScriptDrawHandler(draw)

    return layer
end

return createRubCardEffectLayer

