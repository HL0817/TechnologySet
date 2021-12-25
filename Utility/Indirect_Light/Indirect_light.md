# Indirect Light


## 什么是间接光照
先回顾一下渲染公式：
$$\Large L_r(X, \omega_r) = L_e(X, \omega_r) + \int_{\Omega}L_r(X', -\omega_i)f(X, \omega_i, \omega_r) \cos\theta_i d\omega_i$$

