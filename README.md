# GTAvaToon

The official root repository for this project is here https://github.com/rygo6/GTAvaToon.

## What? Why?

Another VRChat Avatar Toon shader!? Why!?

Well, this one is quite different from the others. 

My time spent in VRChat taught me a number of things about the nuances of avatars in a Social VR or "VR Metaverse" context. This specific use case is different enough from typical 3D games that it necessitates some new mentalities and designs for shaders. This is an attempt to start producing something tangible from what I have learned. To go more in depth on the "Why" behind all this, go to the [Learnings and Reasoning](#learnings-and-reasonings) section.

### Unique Features and Technical Aspects

- The outline is done in a way similar to modern cell shaded games where it samples the normal and depth map. No other avatar shader that works in VRChat draws a toon outline in this manner. This produces a much more detailed and accurate toon outline compared to the inverse hull method every other avatar shader in VRChat currently uses.


- The lighting model is designed around a novel concept of `Local Lighting` and `World Lighting` specifically to give you greater control over your avatar's lighting and how the world lighting affects it. A major premise behind the design of this shader is that ***you cannot trust the world lighting!*** This intentionally breaks physically accurate lighting to give you more 'Photoshop-like' controls on how to specifically dial in how the world lighting affects your avatar so that you can tame whacky world lighting and keep it within constraints that will always look good.


- Another major premise of this shader is to get it's interpretation of world lighting to look consistent and good across any kind of world lighting setup, even if that world lighting setup is terrible. The lighting math of this shader is partially derived from [this great project](https://github.com/lukis101/VRCUnityStuffs/tree/master/SH) which was an exploration in different Spherical Harmonics techniques. I tested all of them in a wide range of worlds with really terrible lighting, chose one that seems to produce the best results on average and added another tweak. What this means is worlds with whacky light probe data will still look good with this shader. I still have yet to find a world with light probe data that this shader can't make look decent. If you find one, please point it out to me. I also tuned, and hardcoded, a lot of lighting values so that lighting entirely from Light Probes looks ~roughly~ the same as lighting from Light Probes + Dynamic Directional Light.

Again, to understand more of the reasoning behind these design choices go to the [Learnings and Reasoning](#learnings-and-reasonings) section.

### Limitations + Todo
- Toon outlines will not look correct in the Scene View due to the Scene View not having MSAA. Look at them through the game view when adjusting. There is nothing that will be able to fix this.
- Toon outlines appear thinner in the Game View than they do in VR. I am still trying to figure exactly what causes this and offset it. Or if I should even offset it, it might just be perceptual due to VR focusing on a smaller area of the screen.
- You can't have transparency with surfaces drawing an outline. You can do alpha cutout, but I haven't implemented this yet.
- It currently only supports Light Probes and Light Probe + Single Directional Light. It can support point, area, and spot lights, just need to find an ideal way to do this and the time.
- For some reason the outline on the preview of the avatar in the avatar menu in VRChat is really messed up. There may not be a solution to this.
- There are some subtle artifacts on depth outlines in some scenarios that I don't think can ever be fully solved. 80%+ of the work on the first version of this shader actually went just to this, how to make this technique work in the limitations of VRChat. I've tried dozens of different methods and tweaks. The one I came up with I find is the best balance of detail, to artifacts, to ease of use, to performance.

## Installation

1. Open the Unity Package Manager under `Window > Package Manager`.
2. Click the + in the upper left of package manager window.
3. Select 'Add package from git url...'.
4. Paste `https://github.com/rygo6/GTAvaToon.git` into the dialogue and click 'Add'.

## Usage

Currently the shaders ready to be used are:

### `GeoTetra/GTAvaToon/Outline/GTToonMatcap`
This is the main shader you will want to put on you whole avatar. 

You can hover over each field and a tooltip will popup to tell you more about what each one does.

Generally the defaults should be good right out of the box, but there are a few things to watch out for.
- `Depth Bounding Extents` needs to be set large enough to encapsulate your whole avatar. This value should also be the same on all materials on the avatar. By default it is `0.5` which creates a bounding box of 1x1x1 if your avatar is not contained within that size, then increase this value as needed.
- `Line Size` would be the main thing to change to affect the line size. Everything else can be a bit complicated to understand, but the tooltips should help.
- `Depth ID` Materials with different depth ids will always draw a line between them. Ideally you should set this to some random value so that you will draw lines on other people that use this same shader. An editor script will randomize these values by default when an instance of the material is made.
- `Gradient Min Max` on the Depth Outline and Normal Outline sections are the primary way you tune the thresholding of the outline, multiplies should generally not need to be changed. Min should always be smaller than Max! But beware, this also affects the smoothness and anti-aliasing of the outline. If Min and Max are too close together, the line may appear too aliased and grainy, too far apart and may appear too blurry. As you adjust these it is good to zoom in on your avatar in unity GameView and look at how it is affecting the quality of the anti-aliasing on the line. Note: The SceneView is not anti-aliased! So you much look in the GameView to get feedback on this.
- `Local Lighting` defines the lighting on your avatar that will never change, and ignore the world lighting. Currently this is rather simple, offering you a MatCap, Rim Light, Rim Darkening and Ambient Occlusion baked into the vertex colors. I have more plans for Local Lighting settings, but am starting with these as it is what most people are familiar with. They should generally work as expected.
- `AO Vertex Color` Allows you to multiply in AO baked to the vertex colors of your mesh. You can also discard vertices if they are fully occluded by AO, this is useful to prevent things like the body clipping through clothes. If you would like to generate this data on your mesh you can use my other project [GTAvaUtil](https://github.com/rygo6/GTAvaUtil) and the `Bake Vertex AO On Selected...` functionality.
- `Discard Vertex AO Darkness Threshold` Allows you to discard vertices from rendering. This is primarily used as a way to help prevent your avatar's body from clipping through it's clothes. You can bake the necessary data to your vertex colors with the `Bake Vertex Visibility Onto First Selected...` in [GTAvaUtil](https://github.com/rygo6/GTAvaUtil).
- `World Lighting` defines how the lighting of the world will then affect your local lighting. The incoming world lighting can be compressed and shifted via the `Light Levels` section and works the same exact way the 'Levels' panel in Photoshop works. This route I believe is a better method compared to adding emission because it enables you to pull up the lows, compressing them, while still keeping the highs at the same position. Enabling you to set a minimum darkness for your avatar, but then not having it become over bright in bright world lighting.
- `Light Probe Averaging` This let you average incoming light probe data in case you want less light variation coming from the world. If you set this fully to 100 then world lighting will fall across your avatar uniformly and it largely becomes a way to have the brightness of your avatar reflect the world bright to some degree. You need to actually bake down some light probes in your scene with varying levels and colors to see any affect from changing this.

### `GeoTetra/GTAvaToon/IgnoreOutline/GTMatcap`

This the same as`GeoTetra/GTAvaToon/Outline/GTToonMatcap` but with the outline code removed and set to ignore outlines. In case there is something you want with the same shading. You may find that smaller thinner items such as glasses or whiskers produce artifacts with the outline. For those cases it is best to just omit them from the outline entirely. That is what this shader is for.

### `GeoTetra/GTAvaToon/IgnoreOutline/GTUnlit`

This is a shader that will ignore the outline. You may find that smaller thinner items such as glasses or whiskers produce artifacts with the outline. For those cases it is best to just omit them from the outline entirely. That is what this shader is for. 

Technically any shader can be set to ignore the outline by putting its rendering queue higher than 2010.

Join the GeoTetra Discord for further discussion and help. https://discord.gg/nbzqtaVP9J

## Learnings and Reasonings

### 1. People care more about their avatar's lighting looking exactly how they want more than they care about it being realistic or matching the world or anything else.

This is something that is immediately obvious in VRChat from the number of people running around with their avatar completely flat shaded! No lighting at all! Why? Because in an all User-Generated-Content paradigm you cannot rely on the world lighting to be good. If you trust the world lighting, some percentage of the time you will appear terrible. Also, even in worlds with correctly done lighting there can still be overly dark areas or areas where lighting is bland. 

So what was the easy solution? Either people turn off lighting entirely and go flat shaded, or they crank up emission!

Neither of these solutions I think are adequate. Fully ignoring the world lighting can be disruptive to immersion and can also be obnoxious to others if your flying around a dimly lit space with full bright unlit shaders.

My solution is to selectively take *some* of the world lighting, average it, condense it and then apply it on top of an entirely separate lighting model that is local to the avatar. This allows users to define lighting on their avatar exactly as they wish, and then specify the constraints to which the world lighting is allowed to change that. So then you can make your avatar be lit exactly how you want, but then still respect the world lighting to some degree to provide better immersion.

I believe this is an issue that will always exist in this User-Generated 3D Social "Metaverse" use case. That ***you cannot trust the world lighting!***

Yes, this is a complete abomination to anything known as "Physically Correct Lighting" and even other Toon lighting techniques. But that is because, this is not supposed to be either. This is for a novel use case. Where physical accuracy is irrelevant and instead freedom of self-expression and social interaction is primary. Trying to enforce a standardized lighting model and aesthetic across the entire Metaverse would be like trying to enforce a single aesthetic across the entire web. I do not believe physics should be uniformly enforced on everything, that includes the physics of gravity, collision, and also the physics of light. We are not duplicating physical reality, we are creating an entirely novel kind of reality.


### 2. Simpler shading and toon-ish aesthetic increases one's sense of 'avatar embodiment'.

Most of the effort of this shader, so far, and probably the most unique aspect of it, is that it draws toon outlines more like a modern cel shaded game. It samples the normal and depth, and also encodes some of its own data in the buffer. This enables outlines that are both more detailed and more accurate. This was partially done for aesthetic, but it is also because I started to realize the importance of toon shading as it pertains to the psychological effects of VR.

It became clear to me that the shading on an avatar does affect the degree to which your mind will project on the avatar when wearing it in VR with full body tracking. It also became clear to me that Physically Based Rendering carries no correlation to the degree to which this happens, and can actually be obstructive to it. That what tends to induce a greater degree of phantom sense, of your mind projecting itself on your avatar, of 'avatar embodiment' is if:
1. The avatar appears to you more so how your internal mind remembers perception of yourself.
2. Your mind has to process less before it recognizes that internally remembered image of itself.

What I mean by #1 is that, people internally don't remember themselves as a photograph from a DSLR camera, the internal image left in the mind is quite abstracted from literal physical reality. Often if someone sees a DSLR hi-res photo of themselves they will do a second take, either not liking the photo, or questioning "Is that what I really look like?" Because one's internal mental image is not a direct correlation to their literal physical form as a DSLR camera would capture it. My theory is that, the more you can present something to someone which matches that internal mental image of themselves, the more their mind will instinctively project themselves onto the form, creating a greater sense of avatar embodiment and a greater degree of phantom sense.

For #2 I find the more mental energy the mind must use to process a visual before it recognizes it as itself, the less your mind will project onto it. Instead your mind gets absorbed into processing the details of the visual, rather experiencing the visual as yourself. Ideally you want a visual that you can glance at and with minimal mental energy consumed it immediately registers as "You". To understand more of what I mean by this, and also to give credit where this theory is partially derived, read [this page](https://twitter.com/_rygo6/status/1523449506263576576/photo/1) from Scott McCloud's "Understanding Comics". It explains how, if shown a photograph, the mind tends to not project itself onto the photographic form as readily compared to when shown a basic smiley face. As the smiley face is universally and immediately recognizable as some aspect of "You", so when you see a smiley face, it registers to your mind as you smiling. But of course everyone running around as a basic smiley face would be boring. So I am seeking the ideal middle ground between the immediately recognizable smiley face and the realistic form. So your mind still recognizes it as "You" as aptly as the smiley face, but visually it is more idiosyncratic to "You".

Toon outlines I find greatly aid this, as it reduces the noise to signal ratio of whats being visually communicated. It presents to your mind high contrast essential details for your mind to recognize more aptly without having to process as much visual noise. 