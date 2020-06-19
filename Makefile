#COMPILERS
FC  = mpif90
CXX = mpicxx

#COMPILATION FLAGS
FFLAGS   = -c -O2
CXXFLAGS = -c -O2

#VTK STUFF
VTK_DIR=/opt/VTK
VTK_VER=9.0

LIBS_VTK=-L$(VTK_DIR)/lib \
-lvtksys-$(VTK_VER) \
-lvtkloguru-$(VTK_VER) \
-lvtkpugixml-$(VTK_VER) \
-lvtkCommonColor-$(VTK_VER) \
-lvtkCommonCore-$(VTK_VER) \
-lvtkCommonDataModel-$(VTK_VER) \
-lvtkCommonMisc-$(VTK_VER) \
-lvtkCommonExecutionModel-$(VTK_VER) \
-lvtkexpat-$(VTK_VER) \
-lvtkdoubleconversion-$(VTK_VER) \
-lvtklz4-$(VTK_VER) \
-lvtklzma-$(VTK_VER) \
-lvtkzlib-$(VTK_VER) \
-lvtkIOLegacy-$(VTK_VER) \
-lvtkIOCore-$(VTK_VER) \
-lvtkIOXMLParser-$(VTK_VER) \
-lvtkIOXML-$(VTK_VER) \
-lvtkParallelDIY-$(VTK_VER) \
-lvtkParallelCore-$(VTK_VER) \
-lvtkImagingCore-$(VTK_VER) \
-lvtkImagingFourier-$(VTK_VER) \
-lvtkFiltersGeneral-$(VTK_VER) \
-lvtkFiltersCore-$(VTK_VER) \
-lvtkCommonTransforms-$(VTK_VER) \
-lvtkFiltersSources-$(VTK_VER) \
-lvtkFiltersStatistics-$(VTK_VER) \
-lvtkFiltersExtraction-$(VTK_VER) \
-lvtkFiltersGeometry-$(VTK_VER) \
-lvtkCommonMath-$(VTK_VER) \
-lvtkInteractionStyle-$(VTK_VER) \
-lvtkCommonSystem-$(VTK_VER) \
-lvtkCommonComputationalGeometry-$(VTK_VER) \
-lvtkRenderingCore-$(VTK_VER) \
-lvtkRenderingFreeType-$(VTK_VER) \
-lvtkRenderingUI-$(VTK_VER) \
-lvtkglew-$(VTK_VER) \
-lvtkRenderingOpenGL2-$(VTK_VER)# \

INCLUDE_VTK=-I$(VTK_DIR)/include/vtk-$(VTK_VER)

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
