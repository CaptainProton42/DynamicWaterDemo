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

## The finite difference method

So now that we know what equation we want to solve we still have to figure out how to solve it. Generally, this cannot be done analytically so we resort to a much used numerical method: [the finite difference method](https://en.wikipedia.org/wiki/Finite_difference_method). In this method, we discretise the area in which we want to solve our equation into a grid. We then want to retreive the approximate solution at each point of that grid.

In order to execute our finite difference method, we first need to discretize the wave equation as well. For this, we use *stencil*. More specifically, a *five point stencil* for the second derivative in space and a *three point stencil* for the second derivative in time.

Let's start with the spatial derivative: As I stated previously, we dicretize the water surface as a grid. Let's denote $$z_{i, j}$$ as the value of the function $$f$$ at the grid coordinates $$i$$ and $$j$$. Using a *five point stencil* we can then *approximate* the derivative at that point as

$$\begin{aligned}
\Delta f(\mathbf{x}_{ij}) &\approx \frac{\partial^2 f(\mathbf{x}_{i, j})}{\partial x^2} + \frac{\partial^2 f(\mathbf{x}_{i, j})}{\partial y^2} \\
&= \frac{z_{i+1, j} - 2 \cdot z_{i, j} + z_{i-1, j}}{h^2} + \frac{z_{i, j+1} - 2 \cdot z_{i, j} + z_{i, j-1}}{h^2} \\
&= \frac{z_{i+1, j} + z_{i, j+1} - 4 \cdot z_{i, j} + z_{i-1, j} + z_{i, j-1}}{h^2}
\end{aligned}$$

where $$h$$ is the distance between to grid points which is assumed to be equal in $$x$$ and $$y$$ direction. So, in order get the second spatial derivative at point $$(i, j)$$ we need to sample all direct (non-diagonal) neighbours of that point.

However, our system also evolves over time and we need to approximate the time derivative as well. Since our game runs at a certain frame rate, our time discretization is already obvious. We always step forward in time with steps of $\Delta t$, which is just the physics delta time. In order to label the time discretization, we introduce the additional upper index $t$. So now, the displacement at grid point $$(i, j)$$ and time $t$ is denoted by $$z_{i, j}^t$$. In order to now approximate the second time derivate, we can just use the same formula as before but just in one dimension, time:

$$\frac{\partial^2 f(\mathbf{x}, t)}{\partial t^2} \approx \frac{z_{i, j}^{t+1} - 2 \cdot z_{i, j}^t + z_{i, j}^{t-1}}{\Delta t^2}$$

So now that we have dicretized both derivatives, let's just plug the into the initial wave equation and solve for $$z_{i, j}^t$$:

$$\begin{align}
\Delta f(\mathbf{x}, t) - \frac{1}{c^2} \frac{\partial^2 f(\mathbf{x}, t)}{\partial t^2} &= 0 \\
\frac{z_{i+1, j} + z_{i, j+1} - 4 \cdot z_{i, j} + z_{i-1, j} + z_{i, j-1}}{h^2} - \frac{1}{c^2} \cdot \frac{z_{i, j}^{t+1} - 2 \cdot z_{i, j}^t + z_{i, j}^{t-1}}{\Delta t^2} &= 0\\
z_{i, j}^{t+1} &= a \cdot (z_{i+1, j} + z_{i, j+1} + z_{i-1, j} + z_{i, j-1}) + (2 - 4a) \cdot z_{i, j}^t - z_{i, j}^{t-1}
\end{align}$$

where we introduce $$a = \frac{c^2 \Delta t^2}{h^2}$$. In order to obtain a stable simulation, $$a < 0.5$$ needs to hold true. We have thus limits on our choice of $\Delta t$ and $h$, depending on how fast our waves should propagate. Grids with less points (and thus large $h$) are generally more stable but also less accurate. It is desirable to keep $\Delta t$ as small as reasonably possible which means high framerates will benefit our simulation.

