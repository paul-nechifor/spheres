fs = require 'fs'
tmp = require 'tmp'
{exec} = require 'child_process'
Color = require 'color'

exports.getRgbColor = getRgbColor = (c) ->
  "rgb<#{c.join ', '}>"

exports.getProps = getProps = (props) ->
  list = []
  for key, val of props
    list.push key + ' ' + val
  list.join ' '

exports.getPos = getPos = (pos) ->
  '<' + pos.join(',') + '>'

getParams = (opts) ->
  p = []
  if opts.highQuality
    p.push '+A0.0001'
    p.push '+R9'
    opts.width = 1920
    opts.height = 1080
  if opts.mediumQuality
    p.push '+A0.001'
    opts.width = 1920
    opts.height = 1080
  p.push '+W' + (opts.width or 960)
  p.push '+H' + (opts.height or 540)
  p.push '+O' + (opts.output or 'output.png')
  p

exports.render = render = (worldStr, opts, cb) ->
  tmp.file {postfix: '.pov'}, (err, path, fd, cleanUpCb) ->
    return cb err if err
    cmd = 'povray ' + getParams(opts).join(' ') + ' ' + path
    fs.writeFile path, worldStr, (err) ->
      if err
        cleanUpCb()
        return cb err
      exec cmd, (err, stdout, stderr) ->
        cleanUpCb()
        if err
          process.stdout.write stdout + stderr
          return cb err
        cb()

exports.Sphere = class Sphere
  constructor: (@pos, @radius, color) ->
    @pigment =
      color: getRgbColor color
    @finish =
      ambient: 0.25
      diffuse: 0.4
      specular: 0.3
      roughness: 0.008
      reflection: 0.4

  toString: (formStr) -> """
      sphere {
        #{getPos @pos}, #{@radius}
        pigment { #{getProps @pigment} }
        finish { #{getProps @finish} }
      }

    """

exports.World = class World
  constructor: (@header) ->
    @spheres = []

  toString: ->
    @header + @renderSpheres()

  renderSpheres: ->
    list = @spheres.map (s) -> s.toString()
    list.join '\n'

header = """
#version 3.6;
global_settings { assumed_gamma 1.0 }
#default { finish { ambient 0.1 diffuse 0.9 } }

#include "colors.inc"
#include "textures.inc"

camera {
  location  <0.0, 0.0, 0.0>
  look_at <0.0, 0.0, 10.0>
  right x*image_width/image_height
  angle 75
}

light_source{<1500,3000,-2500> color White}

/*
fog {
  fog_type   2
  distance   125
  color      rgb<0.1,0.1,0.4>
  fog_offset 0.1
  fog_alt    0.5
  turbulence 0.2
}

plane {
  <0,1,0>, -10
  texture {
    pigment {rgb <0.1, 0.1, 0.1>}
    finish {
      ambient 0.02
      diffuse 0.15
      brilliance 6.0
      phong 0.3
      phong_size 120
      reflection 0.6
    }
  }
  normal {
    bozo 1.75
    scale <2.0,1,0.3> * 1.20
    rotate<0,10,0>
    turbulence 0.9
  }
}
*/

"""

main = ->
  world = new World header
  for i in [1 .. 10000]
    xr = Math.random()
    pos = [
      (xr - 0.5) * 100
      (Math.random() - 0.5) * 60
      60 + (Math.random() * 40)
    ]
    h = 240 + xr * 120
    c = Color h: h, s: 100, l: 50
    color = c.rgbArray().map (c) -> c / 255
    world.spheres.push new Sphere pos, 1, color
  opts =
    output: __dirname + '/../private/out.png'
    mediumQuality: true
  render world.toString(), opts, (err) ->
    throw err if err

main()
