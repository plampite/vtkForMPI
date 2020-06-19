# vtkForMPI
vtkForMPI is a just a stub, a proof of concept, that shows how to connect a Fortran MPI client program with a C++ MPI server program that has VTK visualization capabilities.

You can think of it as the "third way" of having Fortran work with VTK, where the first, common, one is by writing files that VTK based applications (e.g., Paraview) can read, and the second one is by writing explicit Fortran interfaces for an external C++ visualization routine.

The third route exploited here is by sending MPI messages between the two independent applications. This is not much different from the second route, but cooler as it opens up to lot more possibilities as server and client are fully independent (to the point of being in different programming languages; by the same token one could very simply write a GUI for a Fortran program that already takes input from console or text files, or use the same approach for in-situ visualizations).

This simple example actually predates an example from Section 10.3 of "Using Advanced MPI" by W. Gropp et al., where visualization on the server side is only implied in their example, and here it is made slightly more concrete by using VTK.

I'm not a C++ or client/server expert, and in general I didn't put too much effort to cover corner cases and similar stuff, I just wanted to test the possibility of doing this (especially when only using a makefile instead of Cmake). Thus, do not expect production ready code.

## Requirements
I tested this on Ubuntu 20.04 with VTK 9.0, MPICH 3.3.2, CMake 3.17.3, default gcc compilers and make. In order to compile and run the two applications (server and client) you need:

1) MPICH 3.3.2 MPI Library (MPICH is the most straightforward to use MPI library for the client/server features we need) and the resulting mpicxx and mpif90 wrappers
2) VTK 9.0 (which in turn needs Cmake to be compiled)

both installed using the default instructions that I won't repeat here. Note however that the Makefile assumes you have VTK 9.0 installed in /opt/VTK. Change the makefile according to the VTK version you use and its install location.

## Compilation
When all the requirements are satisfied, you can just type "make" to compile both server and client (everything in source tree, sorry about that).

## Running the codes
It obviously makes sense to first start the server but, before doing it, you will probably need to add the VTK lib folder to $LD_LIBRARY_PATH (e.g., export LD_LIBRARY_PATH=/opt/VTK/lib:$LD_LIBRARY_PATH for VTK installed in /opt/VTK). Once done, you can launch the server with:

    mpirun -np 1 ./server

There is, in principle, the chance to run the server (and the client) with more than a single process, but honestly this is largely untested, so let them go with a single proc. Once the server is started, it will write a file named "vtkForMPI-port" which has to be readable by the client in order to connect to the server.

The client can be started in another shell with:

    mpirun -np 1 ./client
    
and, as first thing, will require the name of the file written by the server which, again, is "vtkForMPI-port". If everything works as expected, interaction with the server starts. Look at the source code to see how to interact.

A typical interaction would be:

    hello
    1
    0, 0, 0, 1, 5

then, at this point, a VTK window should open with a cylinder created with your parameters (e.g., radius 1 and height 5) and you should be able to interact with it. Once the window is closed, a new interaction can be started. To shutdown server and client just send "close" as message.
