# GTAvaToon

## What? Why?

This is an Avatar Toon Shader intended to be used in VRChat. My time spent in VRChat and other Social VR platforms taught me a number of things about the particular nuances of avatars specifically in a Social VR or "VR Metaverse" context. This shader is an attempt to turn those learnings into something tangible.

### 1. People care more about their avatar's lighting looking exactly how they want more than they care about it being realistic or matching the world or anything else.

This is something that is immediately obvious in VRChat from the number of people running around with their avatar completely flat shaded! No lighting at all! Why? Because in an all User-Generated-Content paradigm you cannot rely on the world lighting to be good. If you trust the world lighting, some percentage of the time you will appear terrible. Also, even in worlds with correctly done lighting, if there is a darker area, people still want to be clearly visible. It is after all a social experience primarily and being obscured by shadows is disruptive to seeing each other and interacting with each other. 

So what was the easy solution? Either people turn off lighting entirely and go flat shaded, or they crank up emission!

Neither of these solutions I think are adequate. Fully ignoring the world lighting can be disruptive to immersion and can also be obnoxious to others if your flying around a dimly lit space with full bright unlit shaders.

My solution is to selectively take *some* of the world lighting, average it, condense it and then apply it on top of an entirely separate lighting model that is local to the avatar. This allows users to define lighting on their avatar exactly as they wish, and then specify the constraints to which the world lighting is allowed to change that.

Yes. This a complete abomination to anything known as "Physically Correct Lighting" and even other Toon lighting techniques. But that is because, this is not supposed to be either. This is for a novel use case. Where physical accuracy is irrelevant, and instead freedom of self-expression and social interaction is primary. Trying to enforce a standardized lighting model and aesthetic across the entire Metaverse would be like trying to enforce a single aesthetic across the entire web. 

#### World Lighting and Local Lighting
A fundamental concept of this shader that is currently implemented, and I am going to continue to build upon is what I termed `Local Lighting` and `World Lighting`.

`Local Lighting` defines the lighting on your avatar that will never change, and ignore the world lighting. Currently this is rather simple, offering you a MatCap, Rim Light, Rim Darkening and Ambient Occlusion baked into the vertex colors. I have more plans for Local Lighting settings, but am starting with these as it what most people are familiar with.

`World Lighting` defines how the lighting of the world will then affect your local lighting. This where this shader actually offers something rather novel not on others. 

The incoming world lighting can be compressed and shifted in same exact way the 'Levels' panel in Photoshop lets you compress and shift brightness of an image. It is actually the same exact math as photoshop.

This route I believe is a better method compared to adding emission because it enables you to pull up the the lows, compressing them, while still keeping the highs at the same position. Enabling you to set a minimum darkness for your avatar, but then not having it become over bright in bright world lighting.

#### Light Probe Averaging

Another novel option available in the `World Lighting` section is the ability to set a `Probe Average`. This will average the incoming light probe data. This will end up flattening bright and dark contrast of any incoming light, it will also lower the saturation of colors. If you are standing exactly in between a red, green and blue light with this set to 1 for full averaging, then it will create white light with an averaged luminosity.




## Settings

### Local Lighting
#### Light Levels

### World Lighting
#### Light Levels
This settings work the exact same as the Photoshop Levels panel to condense and shift the incoming world lighting levels. Tweak them to condense the lighting to stay within a range of minimum and maximum lighting levels.
- **Black Level:** 
  - Clip black level from world lighting.
- **White Level:** 
  - Clip white levels from world lighting.
- **Output Black Level:** 
  - Compress black levels from world lighting upward.
- **Output White Level:** 
  - Compress white levels from world lighting downwards.
- **Gamma:** 
  - Gamma of world lighting.

#### Light Probes

- **Probe Average:**
    - Average light probe values. 1 is fully averaged. 100 is no averaging.


## ????

Currently it is set up to produce roughly the same lighting whether a world is only with baked Light Probes, of it is also lit with a realtime Directional Light 






This particular style of shading is also a complete abomination to all conceptions of "Good Physically Based Lighting". It's also an abomination to some concepts of Toon shading too! 

My general mentality about the Metaverse is "Fuck Physics", that includes rigid/soft body simulation, gravity, and the physics of light too. We don't need the constraints of physical reality forced upon us in the Metaverse. If I want to fly, I should get to fly. If I want to distort the lighting of the world as it hits my avatar, I should get to. Sure physical constraints should be optional for fun, but not the default forced standard. 

I believe the thing to try to replicate in VR is much more so what one experiences in dream states, the direct perception of your mind, not the optics of a DSLR camera.

Here is a longer caffeine-fueled rant about the [Why](#why).

## Features




## Why? 

Might seem odd to toss another "Toon" shader in VRChat Avatar land but it became clear to me to do what I wanted I really needed to dig into it myself. Currently this does offer some shading techniques that objectively do not exist in anything else available for VRChat right now, and I have more novel techniques I intend to add. But more so the philosophy behind the development of this shader is different. To those uninitiated with VRChat avatars, full body tracking, and the whole notion of "Avatar Binding" or "Phantom Sense" you may see this shader as a complete mutilation of all things considered proper in lighting, which it may be, but it's because it's aim is entirely tangential to "correct" lighting or "Physically Based" lighting. The single driving question behind this shader is, "What increases Phantom Sense?"

It became clear to me that the shading on an avatar does affect the degree to which your mind will project on the avatar when wearing it in VR with full body tracking. It also became clear to me that Physically Based Rendering carries no correlation to the degree to which this happens, and can actually be obstructive to it. That what tends to induce a greater degree of phantom sense, of your mind projecting itself on your avatar, is if:
1. The avatar appears to you more so how your internal mind remembers perception of yourself.
2. Your mind has to process less before it recognizes that internally remembered image of itself.

What I mean by #1 is that, people internally don't remember themselves as a photograph from a DSLR camera, the internal image left in the mind is quite abstracted from literal physical reality. Often if someone sees a DSLR hi-res photo of themselves they will do a second take, either not liking the photo, or questioning "Is that what I really look like?" Because one's internal mental image is not a direct correlation to their literal physical form as a DSLR camera would capture it. My theory is that, the more you can present something to someone which matches that internal mental image of themselves, the more their mind will instinctively project themselves onto the form, creating a greater sense of binding to the avatar, and a greater degree of phantom sense.

For #2, I find the more mental energy the mind must use to process a visual before it recognizes it as itself, the less your mind will project onto it. Instead your mind gets absorbed into processing the details of the visual, rather experiencing the visual as itself. Ideally you want a visual that you can glance at and with minimal mental energy consumed it immediately registers as "You". To understand more of what I mean by this, and also to give credit where this theory is partially derived, read [this page](https://twitter.com/_rygo6/status/1523449506263576576/photo/1) from Scott McCloud's "Understanding Comics". It explains how, if shown a photograph, the mind tends to not project itself onto the photographic form as readily compared to when shown a basic smiley face. As the smiley face is universally and immediately recognizable as some aspect of "You", so when you see a smiley face, it registers to your mind as you smiling. But of course everyone running around as a basic smiley face would be boring. So I am seeking the ideal middle ground between the immediately recognizable smiley face and the realistic form. So your mind still recognizes it as "You" as aptly as the smiley face, but visually it is more idiosyncratic to "You".

Each feature of this shader, and any future features, stem from a supposed theory and observation about what may increase phantom sense. So far, and what will probably continue to be the trend in features, are things that may theoretically enable more immediate recognition of a form that are as simple as possible, and do not consume any more mental energy than the bare minimum for the form to register to your mind. As such, I am not going to be apt to add things like flashy effects, maybe at some point, but I will tend to be interested in additions and changes that have some decent reasoning as to how they could increase phantom sense. I will also tend to listen more so to those who I know experience this phenomena strongly in VR and share my interest in trying to figure out what can amplify it through first-hand observation and experience within VR.

Will need to document theories behind current features so far. Probably in wiki?
