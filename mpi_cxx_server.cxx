//Server stuff
#include "mpi.h"
#include <fstream>
#include <iostream>

//VTK stuff required when using a makefile (as opposed to Cmake)
#include <vtkAutoInit.h>
VTK_MODULE_INIT(vtkRenderingOpenGL2)
VTK_MODULE_INIT(vtkInteractionStyle)

//VTK stuff required by the specific example
#include <vtkActor.h>
#include <vtkCamera.h>
#include <vtkCylinderSource.h>
#include <vtkNamedColors.h>
#include <vtkPolyDataMapper.h>
#include <vtkProperty.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkRenderer.h>
#include <vtkSmartPointer.h>
#include <vtkInteractorStyleTrackballCamera.h>
#include <array>

//Forward declaration of our vtk subroutine (where all VTK stuff actually is)
void vtk_example(double const params[5]);

int main(int argc, char *argv[])
{
   int myid, nproc, master, nproc_client, codein, codeout;
   int cflag, eflag;
   MPI_Comm client;
   MPI_Status status;
   char port_name[MPI_MAX_PORT_NAME];

   //Initialize MPI
   MPI_Init(&argc,&argv);
   MPI_Comm_rank(MPI_COMM_WORLD,&myid);
   MPI_Comm_size(MPI_COMM_WORLD,&nproc);

   master = 0;

   //Open port to incoming connections and write its name to file
   //Also print some useful info to interact with server
   MPI_Open_port(MPI_INFO_NULL,port_name);
   if (myid==master)
   {
      std::string myfile="vtkForMPI-port";
      std::ofstream file_port(myfile);
      file_port << port_name;
      std::cout << "VTK-MPI Server up and running." << std::endl;
      std::cout << "Port name available in file " << myfile << std::endl;
   }


   cflag = 0;
   while (cflag==0) //Main loop in search of incoming connections
   {
      MPI_Comm_accept(port_name,MPI_INFO_NULL,master,MPI_COMM_WORLD,&client); //Wait incoming client connection
      MPI_Comm_remote_size(client,&nproc_client); //How many processes in client (not really used at the moment)
      eflag = 0;
      while (eflag==0) //Client loop
      {
         if (myid==master)
         {
            //Probing messages following our strict protocol based on TAGS
            //STEP 1 - TAG 1: text message to instruct server on what to do
            MPI_Probe(MPI_ANY_SOURCE,1,client,&status);
            //Find out length of message
            int msgsize;
            MPI_Get_count(&status,MPI_CHAR,&msgsize);
            //Receive message
            char msg[msgsize];
            MPI_Recv(&msg,msgsize,MPI_CHAR,status.MPI_SOURCE,1,client,MPI_STATUS_IGNORE);
            std::string rcvmsg = msg;           
            std::cout << "Server received message: " << rcvmsg << std::endl;

            //Take action based on message
            if (rcvmsg=="hello")
            {
               //Send confirmation that we are ready to receive
               codeout = 1;
               MPI_Send(&codeout,1,MPI_INT,status.MPI_SOURCE,0,client);
               //STEP 2 - TAG 2: start receiving data
               MPI_Recv(&codein,1,MPI_INT,status.MPI_SOURCE,2,client,MPI_STATUS_IGNORE);
               //STEP 3 - TAG 3: receive context specific data
               codeout = codein;
               if (codein==1)
               {
                  double params[5];
                  MPI_Recv(&params,5,MPI_DOUBLE,status.MPI_SOURCE,3,client,MPI_STATUS_IGNORE);
                  std::cout << "Server received parameters: ";
                  for (int i=0;i<5;++i) std::cout << params[i] << " ";
                  std::cout << "\n";
                  vtk_example(params); //This is where all the VTK magic is happening
               }
               //Maybe add other use cases here
               else
               {
                  //Didn't understand the request
                  codeout = -codein;
               }
               //STEP 4 - Finish request
               std::cout << "Server closing session with: " << codeout << std::endl;
               MPI_Send(&codeout,1,MPI_INT,status.MPI_SOURCE,0,client);
            }
            else if(rcvmsg=="close") //Shutdown server
            {
               codeout=0;
               MPI_Send(&codeout,1,MPI_INT,status.MPI_SOURCE,0,client);
               std::cout << "Server disconnected" << std::endl;
               eflag=1;
               cflag=1;
            }
            else //Message not understood, disconnect from client
            {
               codeout=-1;
               MPI_Send(&codeout,1,MPI_INT,status.MPI_SOURCE,0,client);
               std::cout << "Connection with client closed" << std::endl;
               eflag=1;
            }
         }
         MPI_Bcast(&eflag,1,MPI_INT,master,MPI_COMM_WORLD); //Notify other processes if client loop is over
         if (eflag==1) MPI_Comm_disconnect(&client); //If client loop is over, disconnect
      }
      MPI_Bcast(&cflag,1,MPI_INT,master,MPI_COMM_WORLD); //Notify other processes that main loop is over
   }//End of main loop

   //Close port and finalize MPI
   MPI_Close_port(port_name);
   MPI_Finalize();

   return 0;
}

//This is just a simple VTK example to test the feature
void vtk_example(double const params[5])
{
  vtkSmartPointer<vtkNamedColors> colors = vtkSmartPointer<vtkNamedColors>::New();

  // Set the background color.
  std::array<unsigned char, 4> bkg{{26, 51, 102, 255}};
  colors->SetColor("BkgColor", bkg.data());

  // This creates a polygonal cylinder model with eight circumferential facets
  vtkSmartPointer<vtkCylinderSource> cylinderSource = vtkSmartPointer<vtkCylinderSource>::New();
  cylinderSource->SetCenter(params[0], params[1], params[2]);
  cylinderSource->SetRadius(params[3]);
  cylinderSource->SetHeight(params[4]);
  cylinderSource->SetResolution(8);

  // The mapper is responsible for pushing the geometry into the graphics library.
  // It may also do color mapping, if scalars or other attributes are defined.
  vtkSmartPointer<vtkPolyDataMapper> cylinderMapper = vtkSmartPointer<vtkPolyDataMapper>::New();
  cylinderMapper->SetInputConnection(cylinderSource->GetOutputPort());

  // The actor is a grouping mechanism: besides the geometry (mapper), it
  // also has a property, transformation matrix, and/or texture map.
  // Here we set its color and rotate it around the X and Y axes.
  vtkSmartPointer<vtkActor> cylinderActor = vtkSmartPointer<vtkActor>::New();
  cylinderActor->SetMapper(cylinderMapper);
  cylinderActor->GetProperty()->SetColor(colors->GetColor4d("Tomato").GetData());
  cylinderActor->RotateX(30.0);
  cylinderActor->RotateY(-45.0);

  // The renderer generates the image which is then displayed on the render window.
  // It can be thought of as a scene to which the actor is added
  vtkSmartPointer<vtkRenderer> renderer = vtkSmartPointer<vtkRenderer>::New();
  renderer->AddActor(cylinderActor);
  renderer->SetBackground(colors->GetColor3d("BkgColor").GetData());
  // Zoom in a little by accessing the camera and invoking its "Zoom" method.
  renderer->ResetCamera();
  renderer->GetActiveCamera()->Zoom(1.5);

  // The render window is the actual GUI window that appears on the computer screen
  vtkSmartPointer<vtkRenderWindow> renderWindow = vtkSmartPointer<vtkRenderWindow>::New();
  renderWindow->SetSize(300, 300);
  renderWindow->AddRenderer(renderer);
  renderWindow->SetWindowName("vtkForMPI Example");

  // The render window interactor captures mouse events and will perform appropriate camera or actor manipulation
  // depending on the nature of the events.
  vtkSmartPointer<vtkRenderWindowInteractor> renderWindowInteractor = vtkSmartPointer<vtkRenderWindowInteractor>::New();
  renderWindowInteractor->SetRenderWindow(renderWindow);

  //The Paraview interactor style
  vtkSmartPointer<vtkInteractorStyleTrackballCamera> style = vtkSmartPointer<vtkInteractorStyleTrackballCamera>::New();
  renderWindowInteractor->SetInteractorStyle(style);

  // This starts the event loop and as a side effect causes an initial render.
  renderWindowInteractor->Start();

  // We get back here as soon as you close the window
  std::cout << "vtk_example (hopefully) worked as expected" << std::endl;
}
