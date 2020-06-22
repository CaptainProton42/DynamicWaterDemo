# Dynamic Water

<div align="center"><iframe width="730px" height="730px" frameBorder="0" src="water.html"></iframe></div>

Click anywhere to interact with objects or spawn crates. You can also change the quality of the water texture and reset the scene.

## Implementation

My implementation uses a finite-differencing method in order to solve the physical equation governing the behaviour of open water surface waves, the wave equation, on a grid. I used the paper [Real-Time Open Water Environments with Interacting Objects](https://www.researchgate.net/publication/221314832_Real-Time_Open_Water_Environments_with_Interacting_Objects) by H. Cords and O. Staadt as a reference. If you want to know more about the technical aspects of this implementation or more advanced collision detection methods, it's a really good read.

## The wave equation

An important equation in phyiscs is the so-called [wave equation](https://en.wikipedia.org/wiki/Wave_equation). It describes the propagation of many types of waves like water waves, sound waves and even light. It therefore plays an important role in many fields of physics like optics and electrodynamics, acoustics and fluid dynamics.

The equation itself is a [hyperbolic partial differential equation of second order](https://en.wikipedia.org/wiki/Hyperbolic_partial_differential_equation). If this sounds very heavy, don't worry, the equation itself is actually quite short:

$$\Delta f(\mathbf{x}, t) - \frac{1}{c^2} \frac{\partial^2 f(\mathbf{x}, t)}{\partial t^2} = 0$$

Here, $$t$$ is the current time, $$\mathbf{x} \in \mathbb{R}^2$$ is the position on the water surface and $$c$$ is the wave speed. $$f(\mathbf{x}, t)$$ then denotes the displacement, that is height, of the water surface at the observed position $$\mathbf{x}$$ and time $$t$$.

The opertator $$\Delta$$ is the so-called Laplace operator and denotes the *sum of the second spatial derivatives in every direction*:

$$\Delta = \frac{\partial^2}{\partial x^2} + \frac{\partial^2}{\partial y^2}$$

Thus we can see that the wave equation connects the second spacial derivates of the water surface with its second derivative in time. This property results in the motion of waves as we would observe it in nature.
