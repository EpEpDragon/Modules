%A circle in 3D is parameterized by six numbers: two for the orientation of its unit normal vector, one for the radius, and three for the circle center.

rad = 1
pos = [0,0,0]
n = [1,0,0]
color = [1,0,0]
%https://demonstrations.wolfram.com/ParametricEquationOfACircleIn3D/
%draws a 3D circle at position pos with radius rad, normal to the
%circle n, and color color.
phi = atan2(n(2),n(1)); %azimuth angle, in [-pi, pi]
theta = atan2(sqrt(n(1)^2 + n(2)^2) ,n(3));% zenith angle, in [0,pi]    
t = 0:pi/32:2*pi;
x = pos(1)- rad*( cos(t)*sin(phi) + sin(t)*cos(theta)*cos(phi) );
y = pos(2)+ rad*( cos(t)*cos(phi) - sin(t)*cos(theta)*sin(phi) );
z = pos(3)+ rad*sin(t)*sin(theta);
plot3(x,y,z)
xlabel("X")
ylabel("Y")
zlabel("Z")
axis("equal")
    
% % then call the function as 
% pos = rand(3,1);rad = 1;R = eye(3);
% drawCircle(rad,pos,R(:,1),'r')
% hold on
% drawCircle(rad,pos,R(:,2),'g')
% drawCircle(rad,pos,R(:,3),'b')
% axis equal