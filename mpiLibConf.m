function [primary, extras] = mpiLibConf
%mpiLibConf Return the location of an MPI implementation
%   [primaryLib, extras] = mpiLibConf returns the MPI implementation library
%   to be used by a parallel job. primaryLib must be the name of the shared
%   library file containing the MPI entry points. extras must be a cell
%   array of other library names required by the MPI library. The libraries
%   can be specified using full filenames if they are not available via the
%   PATH environment variable (on Windows), LD_LIBRARY_PATH (on Linux and
%   Solaris) or DYLD_LIBRARY_PATH (on Macintosh).
%
%   To supply an alternative MPI implementation, create a MATLAB file called
%   "mpiLibConf" and place it on the MATLAB path. The recommended location is
%   <matlabroot>/toolbox/parallel/user/
%   but we are adding it to
%   <matlabroot>/support_packages/matlab_parallel_server/scripts/
%
%   Under all circumstances, the MPI library must support all MPI-1
%   functions. Additionally, the MPI library must support null arguments to
%   MPI_Init as defined in section 4.2 of the MPI-2 standard. The library
%   must also use an "mpi.h" header file which is fully compatible with
%   MPICH2.
%
%   When used with the DCT jobmanager, the MPI library must support the
%   following additional MPI-2 functions:
%   - MPI_Open_port
%   - MPI_Comm_accept
%   - MPI_Comm_connect
%
%   This product includes MD5 software developed by the OpenSSL Project for
%   use in the OpenSSL Toolkit (http://www.openssl.org/).
%   This product includes MD5 software written by Eric Young
%   (eay@cryptsoft.com).

%   Copyright 2005-2021 The MathWorks, Inc.

% Check first if we're running the local scheduler - if we are, then get the default and exit
dfcn = getenv('MDCE_DECODE_FUNCTION');
if strcmp(dfcn, 'parallel.internal.decode.localMpiexecTask')
    % Get the local scheduler's default libs
    [primary, extras] = parallel.internal.mpi.libConfs( 'default' );
else
    % We're not running the local scheduler or using the default MATLAB libmpich
    primary = '${EBROOTPSMPI}/lib/libmpich.so';

    % mvapich has two extra libraries libmpl.so and libopa.so  
    %  use # ldd <mpi-root-path>/lib/libmpich.so
    %   Any libraries from the mpich/mvapich install location need to be included in extras
    extras = {
          '${EBROOTPSMPI}/lib/libmpl.so',
	  '${EBROOTPSMPI}/lib/libopa.so',
	  % Libs from 'ldd ${EBROOTPSMPI}/lib/libmpich.so'
% EXTRALIBS
    };
end
