#COMPILERS
FC  = mpif90
CXX = mpicxx

#COMPILATION FLAGS
FFLAGS   = -c -O2
CXXFLAGS = -c -O2

#VTK STUFF
LIBS_VTK=-L/usr/local/lib \
-lvtkCommonColor-8.90 \
-lvtkCommonCore-8.90 \
-lvtkCommonExecutionModel-8.90 \
-lvtkFiltersSources-8.90 \
-lvtkInteractionStyle-8.90 \
-lvtkRenderingCore-8.90 \
-lvtkRenderingFreeType-8.90 \
-lvtkRenderingOpenGL2-8.90# \

INCLUDE_VTK=-I/usr/local/include/vtk-8.90

#ALL STUFF
LIBS_CLIENT=#
INCLUDE_CLIENT=#

LIBS_SERVER=$(LIBS_VTK)
INCLUDE_SERVER=$(INCLUDE_VTK)

#SOURCES
CLIENT_SRC = mpi_for_client.f90
SERVER_SRC = mpi_cxx_server.cxx

#OBJECTS
CLIENT_OBJ = $(CLIENT_SRC:.f90=.o)
SERVER_OBJ = $(SERVER_SRC:.cxx=.o)

#TARGETS
CLIENT = client
SERVER = server

.PHONY : all clean

#MAIN TARGET
all: $(CLIENT) $(SERVER)

#LINKING RULES
$(CLIENT): $(CLIENT_OBJ)
	$(FC) $(LDFLAGS) $^ -o $@ $(LIBS_CLIENT)

$(SERVER): $(SERVER_OBJ)
	$(CXX) $(LDFLAGS) $^ -o $@ $(LIBS_SERVER)

#COMPILATION RULES
$(CLIENT_OBJ) : $(CLIENT_SRC)
	$(FC) $^ -o $@ $(FFLAGS) $(INCLUDE_CLIENT)

$(SERVER_OBJ) : $(SERVER_SRC)
	$(CXX) $^ -o $@ $(CXXFLAGS) $(INCLUDE_SERVER)

#CLEAN TARGET
clean: 
	rm -rf $(CLIENT) $(CLIENT_OBJ) $(SERVER) $(SERVER_OBJ)
