program mpi_client
        use, intrinsic :: iso_c_binding
        use mpi
        implicit none

        integer, parameter :: buffer_len=1024
        integer :: myid, nproc, nproc_server, ierr, fu, master, cflag
        integer :: server, mpistatus(MPI_STATUS_SIZE)
        character(len=MPI_MAX_PORT_NAME) :: port_name
        character(len=buffer_len)        :: file_port
        real(c_double), allocatable    :: ra(:)
        integer(c_int)                 :: codein, codeout
        character(len=buffer_len,kind=c_char) :: msg

        master=0

        !Initialize MPI
        call MPI_INIT(ierr)
        call MPI_COMM_RANK(MPI_COMM_WORLD,myid,ierr)
        call MPI_COMM_SIZE(MPI_COMM_WORLD,nproc,ierr)

        !Read server port name from user-specified file
        if (myid.eq.master) then
           write(*,*) 'MPI client'
           write(*,*) 'Insert server port file name:'
           read(*,*) file_port
           fu = 100
           open(unit=fu,file=file_port,status='unknown',form='formatted')
           read(fu,*) port_name
           close(fu)
        endif

        !Connect to server and inquire how many procs it has
        call MPI_COMM_CONNECT(port_name,MPI_INFO_NULL,master,MPI_COMM_WORLD,server,ierr)
        call MPI_COMM_REMOTE_SIZE(server,nproc_server,ierr) !Not really used at the moment

        !Main loop
        if (myid.eq.master) then
           cflag=0
           do while (cflag.eq.0)
              !STEP 1 - TAG 1: use a text message to instruct server what we want to do
              write(*,*) 'Insert message to send:'
              read(*,*) msg
              msg = trim(adjustl(msg))//c_null_char
              call MPI_SEND(msg,len(msg),MPI_CHARACTER,0,1,server,ierr)
              !Server responds with an integer code whose value depends from what it can do with our msg request
              call MPI_RECV(codein,1,MPI_INTEGER,MPI_ANY_SOURCE,0,server,mpistatus,ierr)
              write(*,*) 'Received code:',codein
              if (codein.eq.0) then
                 !As a result of our message ("close") the connection is closed and the server will shut down
                 cflag=1
                 write(*,*) 'Client disconnected.'
                 write(*,*) 'Server down.'
              elseif (codein.lt.0) then
                 !Server didn't like our message and closed our connection, but it is still running
                 cflag=1
                 write(*,*) 'Client disconnected.'
                 write(*,*) 'Server still up and running.'
              else
                 !You were kind enough ("hello"), server asks for further action
                 !STEP 2 - TAG 2: send info data for further action
                 write(*,*) 'Insert int code to send (hint... 1):'
                 read(*,*) codeout
                 call MPI_SEND(codeout,1,MPI_INTEGER,0,2,server,ierr)
                 !In case you sent 1, the server wants 5 more doubles to run the VTK cylinder example
                 if (codeout.eq.1) then
                    !STEP 3 - TAG 3: send context specific data
                    write(*,*) 'Input parameters for VTK example - 5 reals: xc, yc, zc, r, h'
                    allocate(ra(5))
                    read(*,*) ra
                    call MPI_SEND(ra,size(ra),MPI_DOUBLE_PRECISION,0,3,server,ierr)
                    deallocate(ra)
                 endif
                 !Maybe add other options here
                 ! STEP 4 - Session is finally closed with return code codein
                 call MPI_RECV(codein,1,MPI_INTEGER,MPI_ANY_SOURCE,0,server,mpistatus,ierr)
                 WRITE(*,*) 'Received code:',codein
              endif
           enddo
        endif

        !Disconnect from server and finalize MPI
        call MPI_BARRIER(MPI_COMM_WORLD,ierr)
        call MPI_COMM_DISCONNECT(server,ierr)
        call MPI_FINALIZE(ierr)

endprogram mpi_client
