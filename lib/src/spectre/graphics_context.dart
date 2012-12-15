part of spectre;

/*

  Copyright (C) 2012 John McCutchan <john@johnmccutchan.com>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

*/

/** The [GraphicsContext] configures the GPU pipeline and executes draw commands */
class GraphicsContext {
  static final int PrimitiveTopologyTriangles = WebGLRenderingContext.TRIANGLES;
  static final int PrimitiveTopologyLines = WebGLRenderingContext.LINES;
  static final int PrimitiveTopologyPoints = WebGLRenderingContext.POINTS;
  static final int numVertexBuffers = 2;
  static final int numTextures = 3;

  GraphicsDevice _device;
  // Input Assembler
  int _primitiveTopology;
  IndexBuffer _indexBufferHandle;
  List<VertexBuffer> _vertexBufferHandles;
  List<int> _enabledVertexAttributeArrays;
  InputLayout _inputLayoutHandle;
  InputLayout _preparedInputLayoutHandle;
  // VS and PS stages
  ShaderProgram _shaderProgramHandle;
  List<SamplerState> _samplerStateHandles;
  List<Texture> _textureHandles;
  // Rasterizer
  RasterizerState _rasterizerStateHandle;
  Viewport _viewportHandle;
  // Output-Merger
  BlendState _blendStateHandle;
  DepthState _depthStateHandle;
  StencilState _stencilStateHandle;
  RenderTarget _renderTargetHandle;

  void _PrepareTextures() {
  }

  void _logVertexAttributes(int index) {
    var enabled = _device.gl.getVertexAttrib(index, WebGLRenderingContext.VERTEX_ATTRIB_ARRAY_ENABLED);
    var size = _device.gl.getVertexAttrib(index, WebGLRenderingContext.VERTEX_ATTRIB_ARRAY_SIZE);
    var stride = _device.gl.getVertexAttrib(index, WebGLRenderingContext.VERTEX_ATTRIB_ARRAY_STRIDE);
    var type = _device.gl.getVertexAttrib(index, WebGLRenderingContext.VERTEX_ATTRIB_ARRAY_TYPE);
    var normalized = _device.gl.getVertexAttrib(index, WebGLRenderingContext.VERTEX_ATTRIB_ARRAY_NORMALIZED);
    var binding = _device.gl.getVertexAttrib(index, WebGLRenderingContext.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING);
    spectreLog.Info('Vertex Attribute $index $enabled $size $stride $type $normalized $binding');
  }

  void _prepareInputs([bool debug=false]) {
    if (_inputLayoutHandle == 0) {
      spectreLog.Error('Prepare for draw no input layout');
      return;
    }

    InputLayout inputLayout = _inputLayoutHandle;
    if (inputLayout == null) {
      spectreLog.Error('Prepare for draw no input layout.');
      return;
    }

    if (_preparedInputLayoutHandle == _inputLayoutHandle) {
      return;
    }

    _preparedInputLayoutHandle = _inputLayoutHandle;

    // Disable old arrays
    for (int index in _enabledVertexAttributeArrays) {
      if (index == 0) {
        continue;
      }
      _device.gl.disableVertexAttribArray(index);
    }
    _enabledVertexAttributeArrays.clear();

    if (inputLayout._elements == null) {
      return;
    }

    for (var element in inputLayout._elements) {
      VertexBuffer vb = _vertexBufferHandles[element._vboSlot];
      if (vb == null) {
        spectreLog.Error('Prepare for draw referenced a null vertex buffer object');
        continue;
      }
      _device.gl.enableVertexAttribArray(element._attributeIndex);
      vb._bind();
      _device.gl.vertexAttribPointer(element._attributeIndex,
        element._attributeFormat.count,
        element._attributeFormat.type,
        element._attributeFormat.normalized,
        element._attributeStride,
        element._vboOffset);
      // Remember that this was enabled.
      _enabledVertexAttributeArrays.add(element._attributeIndex);
      if (debug) {
        _logVertexAttributes(element._attributeIndex);
      }
    }
    if (_indexBufferHandle != null) {
      IndexBuffer indexBuffer = _indexBufferHandle;
      indexBuffer._bind();
    } else {
      _device.gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, null);
    }
  }

  void _prepareTextures() {
    // TODO: Need to unbind unused texture channels
    for (int i = 0; i < numTextures; i++) {
      SamplerState sampler = _samplerStateHandles[i];
      Texture texture = _textureHandles[i];
      if (sampler == null || texture == null) {
        continue;
      }
      texture._bind(WebGLRenderingContext.TEXTURE0 + i);
      texture._applySampler(sampler);
    }
  }

  GraphicsContext(GraphicsDevice device) {
    _device = device;
    _vertexBufferHandles = new List<VertexBuffer>(numVertexBuffers);
    _samplerStateHandles = new List<SamplerState>(numTextures);
    _textureHandles = new List<Texture>(numTextures);
    _enabledVertexAttributeArrays = new List<int>();
  }

  /// Resets the cached GPU pipeline state
  void reset() {
    // TODO: Update GPU state
    _primitiveTopology = 0;
    for (int index in _enabledVertexAttributeArrays) {
      if (index == 0) {
        continue;
      }
      _device.gl.disableVertexAttribArray(index);
    }
    _preparedInputLayoutHandle = null;
    _enabledVertexAttributeArrays.clear();
    _indexBufferHandle = null;
    for (int i = 0; i < numVertexBuffers; i++) {
      _vertexBufferHandles[i] = null;
    }
    _inputLayoutHandle = null;
    _shaderProgramHandle = null;
    for (int i = 0; i < numTextures; i++) {
      _samplerStateHandles[i] = null;
      _textureHandles[i] = null;
    }
    _rasterizerStateHandle = null;
    _viewportHandle = null;
    _blendStateHandle = null;
    _depthStateHandle = null;
    _stencilStateHandle = null;
    _renderTargetHandle = null;
  }

  /// Configure the primitive topology
  void setPrimitiveTopology(int topology) {
    _primitiveTopology = topology;
  }

  /// Set the IndexBuffer to [indexBufferHandle]
  void setIndexBuffer(IndexBuffer indexBufferHandle) {
    _indexBufferHandle = indexBufferHandle;
  }

  /// Set multiple VertexBuffers in [vertexBufferHandles] starting at [startSlot]
  void setVertexBuffers(int startSlot, List<VertexBuffer> vertexBufferHandles) {
    int limit = vertexBufferHandles.length + startSlot;
    for (int i = startSlot; i < limit; i++) {
      _vertexBufferHandles[i] = vertexBufferHandles[i-startSlot];
    }
  }

  /// Set InputLayout to [inputLayoutHandle]
  void setInputLayout(InputLayout inputLayoutHandle) {
    _inputLayoutHandle = inputLayoutHandle;
  }

  void setIndexedMesh(IndexedMesh im) {
    if (im == null) {
      return;
    }
    setIndexBuffer(im.indexArray);
    setVertexBuffers(0, [im.vertexArray]);
  }

  /// Set ShaderProgram to [shaderProgramHandle]
  void setShaderProgram(ShaderProgram shaderProgramHandle) {
    if (_shaderProgramHandle == shaderProgramHandle) {
      return;
    }
    _shaderProgramHandle = shaderProgramHandle;
    ShaderProgram sp = shaderProgramHandle;
    _device.gl.useProgram(sp._program);
  }

  /// Set RasterizerState to [rasterizerStateHandle]
  void setRasterizerState(RasterizerState rasterizerStateHandle) {
    if (_rasterizerStateHandle == rasterizerStateHandle) {
      return;
    }
    _rasterizerStateHandle = rasterizerStateHandle;
    RasterizerState rs = rasterizerStateHandle;
    if (rs == null) {
      return;
    }
    _device.gl.lineWidth(rs.lineWidth);
    if (rs.cullEnabled) {
      _device.gl.enable(WebGLRenderingContext.CULL_FACE);
      _device.gl.cullFace(rs.cullMode);
      _device.gl.frontFace(rs.cullFrontFace);
    } else {
      _device.gl.disable(WebGLRenderingContext.CULL_FACE);
    }
  }

  /// Set Viewport to [viewportHandle]
  void setViewport(Viewport vp) {
    if (vp == _viewportHandle) {
      return;
    }
    _viewportHandle = vp;
    if (vp == null) {
      return;
    }
    _device.gl.viewport(vp.x, vp.y, vp.width, vp.height);
  }

  /// Set BlendState to [blendStateHandle]
  void setBlendState(BlendState bs) {
    if (_blendStateHandle == bs) {
      return;
    }
    _blendStateHandle = bs;
    if (bs == null) {
      return;
    }
    _device.gl.colorMask(bs.writeRenderTargetRed, bs.writeRenderTargetGreen, bs.writeRenderTargetBlue, bs.writeRenderTargetAlpha);
    if (bs.blendEnable == false) {
      _device.gl.disable(WebGLRenderingContext.BLEND);
      return;
    }
    _device.gl.enable(WebGLRenderingContext.BLEND);
    //_device.gl.blendFunc(bs.blendSourceColorFunc, bs.blendDestColorFunc);
    _device.gl.blendFuncSeparate(bs.blendSourceColorFunc, bs.blendDestColorFunc, bs.blendSourceAlphaFunc, bs.blendDestAlphaFunc);
    _device.gl.blendEquationSeparate(bs.blendColorOp, bs.blendAlphaOp);
    _device.gl.blendColor(bs.blendColorRed, bs.blendColorGreen, bs.blendColorBlue, bs.blendColorAlpha);
  }

  /// Set DepthState to [depthStateHandle]
  void setDepthState(DepthState ds) {
    if (_depthStateHandle == ds) {
      return;
    }
    if (ds == null) {
      return;
    }
    _device.gl.depthRange(ds.depthNearVal, ds.depthFarVal);
    if (ds.depthTestEnabled == false) {
      _device.gl.disable(WebGLRenderingContext.DEPTH_TEST);
    } else {
      _device.gl.enable(WebGLRenderingContext.DEPTH_TEST);
      _device.gl.depthFunc(ds.depthComparisonOp);
    }

    _device.gl.depthMask(ds.depthWriteEnabled);

    if (ds.polygonOffsetEnabled == false) {
      _device.gl.disable(WebGLRenderingContext.POLYGON_OFFSET_FILL);
    } else {
      _device.gl.enable(WebGLRenderingContext.POLYGON_OFFSET_FILL);
      _device.gl.polygonOffset(ds.polygonOffsetFactor, ds.polygonOffsetUnits);
    }
  }

  /// Set RenderTarget to [renderTargetHandle]
  void setRenderTarget(RenderTarget renderTargetHandle) {
    if (_renderTargetHandle == renderTargetHandle) {
      return;
    }
    _renderTargetHandle = renderTargetHandle;
    if (_renderTargetHandle == null) {
      RenderTarget.systemRenderTarget._bind();
    } else {
      RenderTarget rt = renderTargetHandle;
      rt._bind();
    }
  }

  ShaderProgramUniform _findUniform(String name) {
    ShaderProgram sp = _shaderProgramHandle;
    if (sp == null) {
      return null;
    }
    return sp.uniforms[name];
  }

  void setConstant(String name, var argument) {
    ShaderProgramUniform uniform = _findUniform(name);
    if (uniform != null) {
      uniform._apply(_device, uniform.location, argument);
    } else if (_shaderProgramHandle == null ){
      spectreLog.Error('Cannot set $name: no ShaderProgram bound.');
    } else {
      //spectreLog.Error('Cannot set $name: not found.');
    }
  }

  /// Update the pixels of [textureHandle] from the [imageResourceHandle]
  ///
  /// Only updates the top level mip map
  void updateTexture2DFromResource(Texture2D tex, ImageResource ir, ResourceManager rm) {
    if (ir == null) {
      return;
    }
    if (tex == null) {
      return;
    }
    tex.uploadElement(ir.image);
  }

  /// Generate the full mipmap pyramid for [textureHandle]
  void generateMipmap(Texture2D tex) {
    if (tex == null) {
      return;
    }
    tex.generateMipmap();
    tex.ready = true;
  }

  void compileShader(SpectreShader shader, String source) {
    if (shader == null) {
      return;
    }
    shader.source = source;
    shader.compile();
    String shaderCompileLog = _device.gl.getShaderInfoLog(shader._shader);
    spectreLog.Info('Compiled ${shader.name} - $shaderCompileLog');
  }

  void clearColorBuffer(num r, num g, num b, num a) {
    _device.gl.clearColor(r, g, b, a);
    _device.gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT);
  }

  void clearDepthBuffer(num depth) {
    _device.gl.clearDepth(depth);
    _device.gl.clear(WebGLRenderingContext.DEPTH_BUFFER_BIT);
  }

  void clearStencilBuffer(int stencil) {
    _device.gl.clearStencil(stencil);
    _device.gl.clear(WebGLRenderingContext.STENCIL_BUFFER_BIT);
  }

  void compileShaderFromResource(SpectreShader shader, ShaderResource sr, ResourceManager rm) {
    if (sr == null) {
      return;
    }
    compileShader(shader, sr.source);
  }

  void linkShaderProgram(ShaderProgram sp, VertexShader vs, FragmentShader fs) {
    _device.gl.attachShader(sp._program, vs._shader);
    _device.gl.attachShader(sp._program, fs._shader);
    sp.link();
  }

  /// Sets a list of [textureHandles] starting at [texUnitOffset]
  void setTextures(int texUnitOffset, List<Texture> textureHandles) {
    for (int i = texUnitOffset; i < textureHandles.length; i++) {
      _textureHandles[i] = textureHandles[i-texUnitOffset];
    }
  }

  /// Sets a list of [samplerHandles] starting at [texUnitOffset]
  void setSamplers(int texUnitOffset, List<SamplerState> samplerHandles) {
    for (int i = texUnitOffset; i < samplerHandles.length; i++) {
      _samplerStateHandles[i] = samplerHandles[i-texUnitOffset];
    }
  }

  /// Draw an indexed mesh with [numIndices] starting at [indexOffset]
  void drawIndexed(int numIndices, int indexOffset) {
    if (numIndices == 0) {
      return;
    }
    _prepareInputs();
    _prepareTextures();
    _device.gl.drawElements(_primitiveTopology, numIndices, WebGLRenderingContext.UNSIGNED_SHORT, indexOffset);
  }

  void drawIndexedMesh(IndexedMesh im) {
    if (im == null) {
      return;
    }
    drawIndexed(im.numIndices, im.indexOffset);
  }

  /// Draw a mesh with [numVertices] starting at [vertexOffset]
  void draw(int numVertices, int vertexOffset) {
    if (numVertices == 0) {
      return;
    }
    _prepareInputs();
    _prepareTextures();
    _device.gl.drawArrays(_primitiveTopology, vertexOffset, numVertices);
  }
}
