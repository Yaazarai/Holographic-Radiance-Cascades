# Holographic-Radiance-Cascades
Extremely naive implementation using 1/2 HRC model.

HRC casts rays from discrete planes of probes across 4 cardinal frustums (up/down/left/right) then merges the frustums for the final radiance field. Breaks down very quickly on smaller more uniform light sources--unstable. The name "Holographic," RC comes from the idea that radiance is captured over planes much like holograms. This method comes from the Radiance Cascades server and is not my idea.

The primary goal is to eventually fix the aliasing issues and get an implementation that is: volumetric, close to reference path tracing and supports ray-extensions (to eliminate raymarching)... Eventually.

![image](https://github.com/user-attachments/assets/70ea71b0-a8b8-4f6b-ab51-562523d2ecbc)
