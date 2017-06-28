! \file
!> \author Chris Bradley
!> \brief This is an example program to solve a linear elasticity equation using OpenCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> \example LinearElasticity/src/LinearElasticityExample.f90
!! Example program to solve a linear elasticity equation using OpenCMISS calls.
!<

!> Main program
PROGRAM LinearElasticity2DExtensionPlaneStressLagrangeBasis
#ifndef NOMPIMOD
  USE MPI
#endif
  USE OpenCMISS
  USE OpenCMISS_Iron

#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

#ifdef NOMPIMOD
#include "mpif.h"
#endif

  !Test program parameters
  INTEGER(CMISSIntg), PARAMETER :: CoordinateSystemUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: RegionUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: BasisUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: MeshUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: DecompositionUserNumber=1
  INTEGER(CMISSIntg)            :: NumberOfXiCoordinates
  INTEGER(CMISSIntg), PARAMETER :: GeneratedMeshUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: FieldGeometryUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: FieldDependentUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: FieldMaterialUserNumber=3
  INTEGER(CMISSIntg), PARAMETER :: EquationSetUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetFieldUserNumber=4
  INTEGER(CMISSIntg), PARAMETER :: ProblemUserNumber=1
  INTEGER(CMISSIntg)            :: NumberOfSpatialCoordinates

  INTEGER(CMISSIntg),   PARAMETER ::    TIMESTEPS   = 5
  INTEGER(CMISSIntg)              ::    TIMESTEP    = 0
  REAL(CMISSRP),        PARAMETER ::    ORIGIN(3)   = [0.0_CMISSRP,0.0_CMISSRP,0.0_CMISSRP]       
  REAL(CMISSRP),        PARAMETER ::    ZERO        = 0.0_CMISSRP
  REAL(CMISSRP),        PARAMETER ::    THICKNESS   = 1.0_CMISSRP
  
  REAL(CMISSRP)         ::    LENGTH,WIDTH,HEIGHT          
  REAL(CMISSRP)         ::    EMODULE,NU,BCDISP_MAX     
  INTEGER(CMISSIntg)    ::    INTERPOLATION_TYPE,SOLVER_TYPE        
  REAL(CMISSRP)         ::    BCFORCE,BCFORCE_MAX,FORCE
  INTEGER(CMISSIntg)    ::    TOP_SIZE,SIDE_SIZE,row,col
  
  !INTEGER(CMISSIntg),   PARAMETER ::    NUMBER_OF_ARGUMENTS = 11

  !Program variables
  INTEGER(CMISSIntg)                :: NUMBER_OF_ARGUMENTS,ARGUMENT_LENGTH,STATUS
  INTEGER(CMISSIntg)                :: NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS
  CHARACTER(LEN=255)                :: COMMAND_ARGUMENT
  INTEGER(CMISSIntg)                :: MPI_IERROR
  INTEGER(CMISSIntg)                :: EquationsSetIndex
  INTEGER(CMISSIntg)                :: NumberOfComputationalNodes,ComputationalNodeNumber
  INTEGER(CMISSIntg)                :: node_idx,component_idx,NodeNumber,NodeDomain
  INTEGER(CMISSIntg),ALLOCATABLE    :: FrontSurfaceNodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE    :: LeftSurfaceNodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE    :: RightSurfaceNodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE    :: BottomSurfaceNodes(:)
  INTEGER(CMISSIntg)                :: LeftNormalXi,RightNormalXi,FrontNormalXi,BottomNormalXi
  CHARACTER(LEN=256)                :: filename

  !CMISS variables
  TYPE(cmfe_RegionType)             :: WorldRegion
  TYPE(cmfe_CoordinateSystemType)   :: WorldCoordinateSystem
  TYPE(cmfe_BasisType)              :: Basis
  TYPE(cmfe_BoundaryConditionsType) :: BoundaryConditions
  TYPE(cmfe_CoordinateSystemType)   :: CoordinateSystem
  TYPE(cmfe_DecompositionType)      :: Decomposition
  TYPE(cmfe_EquationsType)          :: Equations
  TYPE(cmfe_EquationsSetType)       :: EquationsSet
  TYPE(cmfe_FieldType)              :: GeometricField,DependentField,MaterialField
  TYPE(cmfe_FieldsType)             :: Fields
  TYPE(cmfe_MeshType)               :: Mesh
  TYPE(cmfe_GeneratedMeshType)      :: GeneratedMesh
  TYPE(cmfe_NodesType)              :: Nodes
  TYPE(cmfe_ProblemType)            :: Problem
  TYPE(cmfe_RegionType)             :: Region
  TYPE(cmfe_FieldType)              :: EquationsSetField
  TYPE(cmfe_SolverType)             :: Solver
  TYPE(cmfe_SolverEquationsType)    :: SolverEquations

#ifdef WIN32
  ! Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif

  ! Generic CMISS variables
  INTEGER(CMISSIntg) :: Err

#ifdef WIN32
  ! Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  ! Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  ! If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif

!!!!!!!! Command Line Interface !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  NUMBER_OF_ARGUMENTS = COMMAND_ARGUMENT_COUNT()
  IF(NUMBER_OF_ARGUMENTS >= 11) THEN
    ! get extents of spatial domain
    CALL GET_COMMAND_ARGUMENT(1,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 1.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) WIDTH
    IF(WIDTH<=0) CALL HANDLE_ERROR("Invalid width.")
    CALL GET_COMMAND_ARGUMENT(2,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 2.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) HEIGHT
    IF(HEIGHT<=0) CALL HANDLE_ERROR("Invalid height.")
    CALL GET_COMMAND_ARGUMENT(3,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 3.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) LENGTH
    IF(LENGTH<0) CALL HANDLE_ERROR("Invalid length.")
    ! number of elements in each coordinate direction
    CALL GET_COMMAND_ARGUMENT(4,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 4.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) NUMBER_GLOBAL_X_ELEMENTS
    IF(NUMBER_GLOBAL_X_ELEMENTS<=0) CALL HANDLE_ERROR("Invalid number of X elements.")
    CALL GET_COMMAND_ARGUMENT(5,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 5.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) NUMBER_GLOBAL_Y_ELEMENTS
    IF(NUMBER_GLOBAL_Y_ELEMENTS<=0) CALL HANDLE_ERROR("Invalid number of Y elements.")
    CALL GET_COMMAND_ARGUMENT(6,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 6.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) NUMBER_GLOBAL_Z_ELEMENTS
    IF(NUMBER_GLOBAL_Z_ELEMENTS<0) CALL HANDLE_ERROR("Invalid number of Z elements.")
    ! interpolation type (linear, quadratic
    CALL GET_COMMAND_ARGUMENT(7,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 7.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) INTERPOLATION_TYPE
    IF(INTERPOLATION_TYPE<=0) CALL HANDLE_ERROR("Invalid interpolation specification.")
    ! solver type (0: direct linear solve,1: linear iterative solve)
    CALL GET_COMMAND_ARGUMENT(8,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 8.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) SOLVER_TYPE
    IF((SOLVER_TYPE<0).OR.(SOLVER_TYPE>1)) CALL HANDLE_ERROR("Invalid solver type specification.")
    ! Material Parameter -> E-Modulus
    CALL GET_COMMAND_ARGUMENT(9,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 9.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) EMODULE
    IF(EMODULE<=0) CALL HANDLE_ERROR("Invalid E-Module type specification.")
    ! Material Parameter -> Poisson Ratio
    CALL GET_COMMAND_ARGUMENT(10,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 10.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) NU
    IF((NU<=-1.0_CMISSRP) .OR. (NU>0.5_CMISSRP)) CALL HANDLE_ERROR("Invalid Poisson Ratio type specification.")
    ! BC -> Maximum Displacement in percent
    CALL GET_COMMAND_ARGUMENT(11,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 11.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) BCFORCE_MAX
    IF(BCDISP_MAX<=-1.0) CALL HANDLE_ERROR("Invalid BC specification.")
  ELSE
    !If there are not enough arguments default the problem specification 
    WIDTH                       = 160.0_CMISSRP
    HEIGHT                      = 120.0_CMISSRP
    LENGTH                      = 0.0_CMISSRP
    NUMBER_GLOBAL_X_ELEMENTS    = 4
    NUMBER_GLOBAL_Y_ELEMENTS    = 4
    NUMBER_GLOBAL_Z_ELEMENTS    = 0
    INTERPOLATION_TYPE          = CMFE_BASIS_LINEAR_LAGRANGE_INTERPOLATION
    SOLVER_TYPE                 = 0
    EMODULE                     = 10000.0_CMISSRP
    NU                          = 0.3_CMISSRP
    BCFORCE_MAX                 = 4E4_CMISSRP
  ENDIF
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



  ! Intialise cmiss
  CALL cmfe_Initialise(WorldCoordinateSystem,WorldRegion,Err)
  CALL cmfe_ErrorHandlingModeSet(CMFE_ERRORS_TRAP_ERROR,Err)

  WRITE(*,'(A)') "Program starting."
  !NumberGlobalXElements=4
  !NumberGlobalYElements=4

  ! Set all diganostic levels on for testing
  CALL cmfe_DiagnosticsSetOn(CMFE_FROM_DIAG_TYPE,[1,2,3,4,5],"Diagnostics",["PROBLEM_FINITE_ELEMENT_CALCULATE"],Err)

  ! Get the number of computational nodes and this computational node number
  CALL cmfe_ComputationalNumberOfNodesGet(NumberOfComputationalNodes,Err)
  CALL cmfe_ComputationalNodeNumberGet(ComputationalNodeNumber,Err)

  ! Coordinate system
  IF(NUMBER_GLOBAL_Z_ELEMENTS >= 1) THEN
    NumberOfSpatialCoordinates=3
    NumberOfXiCoordinates=3
  ELSE
    NumberOfSpatialCoordinates=2
    NumberOfXiCoordinates=2
  ENDIF
  
  CALL cmfe_CoordinateSystem_Initialise(CoordinateSystem,Err)
  CALL cmfe_CoordinateSystem_CreateStart(CoordinateSystemUserNumber,CoordinateSystem,Err)
  CALL cmfe_CoordinateSystem_TypeSet(CoordinateSystem,CMFE_COORDINATE_RECTANGULAR_CARTESIAN_TYPE,Err)
  CALL cmfe_CoordinateSystem_DimensionSet(CoordinateSystem,NumberOfSpatialCoordinates,Err)
  CALL cmfe_CoordinateSystem_OriginSet(CoordinateSystem,(ORIGIN),Err)
  CALL cmfe_CoordinateSystem_CreateFinish(CoordinateSystem,Err)

  ! Region
  CALL cmfe_Region_Initialise(Region,Err)
  CALL cmfe_Region_CreateStart(RegionUserNumber,WorldRegion,Region,Err)
  CALL cmfe_Region_CoordinateSystemSet(Region,CoordinateSystem,Err)
  CALL cmfe_Region_CreateFinish(Region,Err)

  ! Basis
  CALL cmfe_Basis_Initialise(Basis,Err)
  CALL cmfe_Basis_CreateStart(BasisUserNumber,Basis,Err)
  CALL cmfe_Basis_TypeSet(Basis,CMFE_BASIS_LAGRANGE_HERMITE_TP_TYPE,Err)
  CALL cmfe_Basis_NumberOfXiSet(Basis,NumberOfXiCoordinates,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS >= 1) THEN ! 3D
    CALL cmfe_Basis_InterpolationXiSet(Basis,[INTERPOLATION_TYPE,INTERPOLATION_TYPE,INTERPOLATION_TYPE],Err)  
    CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(Basis,[3,3,3],Err) 
  ELSE ! 2D
    CALL cmfe_Basis_InterpolationXiSet(Basis, [INTERPOLATION_TYPE,INTERPOLATION_TYPE],Err) 
    CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(Basis,[3,3],Err)   
  ENDIF
  
  ! Checkpoint
  WRITE(*,'(A)') "Basis OK."
  
  CALL cmfe_Basis_CreateFinish(Basis,Err)

  ! Generated Mesh
  CALL cmfe_GeneratedMesh_Initialise(GeneratedMesh,Err)
  CALL cmfe_GeneratedMesh_CreateStart(GeneratedMeshUserNumber,Region,GeneratedMesh,Err)
  CALL cmfe_GeneratedMesh_TypeSet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_MESH_TYPE,Err)
  CALL cmfe_GeneratedMesh_BasisSet(GeneratedMesh,Basis,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS >= 1) THEN ! 3D
    CALL cmfe_GeneratedMesh_ExtentSet(GeneratedMesh,[WIDTH,HEIGHT,LENGTH],Err)
    CALL cmfe_GeneratedMesh_NumberOfElementsSet(GeneratedMesh,[NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS, &
      & NUMBER_GLOBAL_Z_ELEMENTS],Err)
  ELSE ! 2D
    CALL cmfe_GeneratedMesh_ExtentSet(GeneratedMesh,[WIDTH,HEIGHT],Err)
    CALL cmfe_GeneratedMesh_NumberOfElementsSet(GeneratedMesh,[NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS],Err)  
  ENDIF
  
  ! Checkpoint
  WRITE(*,'(A)') "Mesh OK."

  ! Mesh
  CALL cmfe_Mesh_Initialise(Mesh,Err)
  CALL cmfe_GeneratedMesh_CreateFinish(GeneratedMesh,MeshUserNumber,Mesh,Err)

  ! Decomposition
  CALL cmfe_Decomposition_Initialise(Decomposition,Err)
  CALL cmfe_Decomposition_CreateStart(DecompositionUserNumber,Mesh,Decomposition,Err)
  CALL cmfe_Decomposition_TypeSet(Decomposition,CMFE_DECOMPOSITION_CALCULATED_TYPE,Err)
  CALL cmfe_Decomposition_NumberOfDomainsSet(Decomposition,NumberOfComputationalNodes,Err)
  CALL cmfe_Decomposition_CreateFinish(Decomposition,Err)

  ! Geometry
  CALL cmfe_Field_Initialise(GeometricField,Err)
  CALL cmfe_Field_CreateStart(FieldGeometryUserNumber,Region,GeometricField,Err)
  CALL cmfe_Field_MeshDecompositionSet(GeometricField,Decomposition,Err)
  CALL cmfe_Field_TypeSet(GeometricField,CMFE_FIELD_GEOMETRIC_TYPE,Err)
  CALL cmfe_Field_VariableLabelSet(GeometricField,CMFE_FIELD_U_VARIABLE_TYPE,"Undeformed",Err)
  CALL cmfe_Field_CreateFinish(GeometricField,Err)
  CALL cmfe_GeneratedMesh_GeometricParametersCalculate(GeneratedMesh,GeometricField,Err)

  ! Equations set
  CALL cmfe_Field_Initialise(EquationsSetField,Err)
  IF(NumberOfSpatialCoordinates==3) THEN ! 3D
    CALL cmfe_EquationsSet_CreateStart(EquationSetUserNumber,Region,GeometricField, &
      & [CMFE_EQUATIONS_SET_ELASTICITY_CLASS, &
      &  CMFE_EQUATIONS_SET_LINEAR_ELASTICITY_TYPE, &
      & CMFE_EQUATIONS_SET_THREE_DIMENSIONAL_SUBTYPE], &
      & EquationsSetFieldUserNumber,EquationsSetField,EquationsSet,Err) 
  ELSE                                    ! 2D
    CALL cmfe_EquationsSet_CreateStart(EquationSetUserNumber,Region,GeometricField, &
      & [CMFE_EQUATIONS_SET_ELASTICITY_CLASS, &
      &  CMFE_EQUATIONS_SET_LINEAR_ELASTICITY_TYPE, &
      & CMFE_EQUATIONS_SET_TWO_DIMENSIONAL_PLANE_STRESS_SUBTYPE], &
      & EquationsSetFieldUserNumber,EquationsSetField,EquationsSet,Err)
  ENDIF
  CALL cmfe_EquationsSet_CreateFinish(EquationsSet,Err)
  
  ! Checkpoint
  WRITE(*,'(A)') "EQ-Set OK."

  ! Dependent field
  CALL cmfe_Field_Initialise(DependentField,Err)
  CALL cmfe_EquationsSet_DependentCreateStart(EquationsSet,FieldDependentUserNumber,DependentField,Err)
  CALL cmfe_Field_VariableLabelSet(DependentField,CMFE_FIELD_U_VARIABLE_TYPE,"Displacement",Err)
  CALL cmfe_Field_VariableLabelSet(DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,"Displacement (derivative)",Err)
  DO component_idx=1,NumberOfSpatialCoordinates
      CALL cmfe_Field_ComponentMeshComponentSet(DependentField,CMFE_FIELD_U_VARIABLE_TYPE,component_idx,1,Err)
      CALL cmfe_Field_ComponentMeshComponentSet(DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,component_idx,1,Err)
  ENDDO
  CALL cmfe_EquationsSet_DependentCreateFinish(EquationsSet,Err)
  
  ! Checkpoint
  WRITE(*,'(A)') "DependentField OK."

  ! Material field
  CALL cmfe_Field_Initialise(MaterialField,Err)
  CALL cmfe_EquationsSet_MaterialsCreateStart(EquationsSet,FieldMaterialUserNumber,MaterialField,Err)
  CALL cmfe_Field_VariableLabelSet(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,"Material",Err)
  CALL cmfe_EquationsSet_MaterialsCreateFinish(EquationsSet,Err)
  IF(NumberOfSpatialCoordinates==3) THEN  ! 3D
    CALL cmfe_Field_ComponentValuesInitialise(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1,EMODULE,Err) ! E11
    CALL cmfe_Field_ComponentValuesInitialise(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,2,EMODULE,Err) ! E22 
    CALL cmfe_Field_ComponentValuesInitialise(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,3,EMODULE,Err) ! E33
    CALL cmfe_Field_ComponentValuesInitialise(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,4,NU,Err)      !v13
    CALL cmfe_Field_ComponentValuesInitialise(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,5,NU,Err)      !v23
    CALL cmfe_Field_ComponentValuesInitialise(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,6,NU,Err)      !v12
  ELSE ! 2D
    CALL cmfe_Field_ComponentValuesInitialise(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1,THICKNESS,Err)
    CALL cmfe_Field_ComponentValuesInitialise(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,2,EMODULE,Err)
    CALL cmfe_Field_ComponentValuesInitialise(MaterialField,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,3,NU,Err) 
  ENDIF
  
  ! Checkpoint
  WRITE(*,'(A)') "MaterialField OK."

  ! Equations
  CALL cmfe_Equations_Initialise(Equations,Err)
  CALL cmfe_EquationsSet_EquationsCreateStart(EquationsSet,Equations,Err)
  CALL cmfe_Equations_SparsityTypeSet(EQUATIONS,CMFE_EQUATIONS_SPARSE_MATRICES,Err)
                                              !CMFE_EQUATIONS_SPARSE_MATRICES=1 !<Use sparse matrices for the equations.
                                              !CMFE_EQUATIONS_FULL_MATRICES=2 !<Use fully populated matrices for the equations.
  CALL cmfe_Equations_OutputTypeSet(EQUATIONS,CMFE_EQUATIONS_NO_OUTPUT,Err)
                                            !CMFE_EQUATIONS_NO_OUTPUT !<No output from the equations.
                                            !CMFE_EQUATIONS_TIMING_OUTPUT !<Timing information output.
                                            !CMFE_EQUATIONS_MATRIX_OUTPUT !<All below and equation matrices output.
                                            !CMFE_EQUATIONS_ELEMENT_MATRIX_OUTPUT !<All below and Element matrices output.
  CALL cmfe_EquationsSet_EquationsCreateFinish(EquationsSet,Err)

  ! Problem
  CALL cmfe_Problem_Initialise(Problem,Err)
  CALL cmfe_Problem_CreateStart(ProblemUserNumber, &
    & [CMFE_PROBLEM_ELASTICITY_CLASS, &
    & CMFE_PROBLEM_LINEAR_ELASTICITY_TYPE, &
    & CMFE_PROBLEM_NO_SUBTYPE],Problem,Err)
  CALL cmfe_Problem_CreateFinish(Problem,Err)

  ! Control Loop
  CALL cmfe_Problem_ControlLoopCreateStart(Problem,Err)
  CALL cmfe_Problem_ControlLoopCreateFinish(Problem,Err)

  ! Solver
  CALL cmfe_Solver_Initialise(Solver,Err)
  CALL cmfe_Problem_SolversCreateStart(Problem,Err)
  CALL cmfe_Problem_SolverGet(Problem,CMFE_CONTROL_LOOP_NODE,1,Solver,Err)
  CALL cmfe_Solver_OutputTypeSet(SOLVER,CMFE_SOLVER_NO_OUTPUT,Err)
                                      !CMFE_SOLVER_NO_OUTPUT !<No output from the solver routines. \see OPENCMISS_SolverOutputTypes,OPENCMISS
                                      !CMFE_SOLVER_PROGRESS_OUTPUT !<Progress output from solver routines.
                                      !CMFE_SOLVER_TIMING_OUTPUT !<Timing output from the solver routines plus below.
                                      !CMFE_SOLVER_SOLVER_OUTPUT !<Solver specific output from the solver routines plus below.
                                      !CMFE_SOLVER_MATRIX_OUTPUT !<Solver matrices output from the solver routines plus below.
!  CALL cmfe_Solver_LibraryTypeSet(SOLVER,CMFE_SOLVER_PETSC_LIBRARY,Err)
!  CALL cmfe_Solver_LinearTypeSet(SOLVER,CMFE_SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE,Err)

  ! Chose Solver Type
  IF(SOLVER_TYPE==0) THEN
    CALL cmfe_Solver_LinearTypeSet(SOLVER,CMFE_SOLVER_LINEAR_DIRECT_SOLVE_TYPE,Err) !<Direct linear solver type.
  ELSEIF(SOLVER_TYPE==1) THEN
    CALL cmfe_Solver_LinearTypeSet(SOLVER,CMFE_SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE,Err) !<Iterative linear solver type.
  ELSE
    CALL cmfe_Solver_LinearTypeSet(SOLVER,CMFE_SOLVER_LINEAR_DIRECT_SOLVE_TYPE,Err) !<Direct linear solver type.
  ENDIF
  
  ! Checkpoint
  WRITE(*,'(A)') "Solver OK."
  
  CALL cmfe_Problem_SolversCreateFinish(Problem,Err)

  ! Solver equations
  CALL cmfe_Solver_Initialise(Solver,Err)
  CALL cmfe_SolverEquations_Initialise(SolverEquations,Err)
  CALL cmfe_Problem_SolverEquationsCreateStart(Problem,Err)
  CALL cmfe_Problem_SolverGet(Problem,CMFE_CONTROL_LOOP_NODE,1,Solver,Err)
  CALL cmfe_Solver_SolverEquationsGet(Solver,SolverEquations,Err)
  CALL cmfe_SolverEquations_SparsityTypeSet(SolverEquations,CMFE_SOLVER_SPARSE_MATRICES,Err)
                                                          !CMFE_SOLVER_SPARSE_MATRICES !<Use sparse solver matrices.
                                                          !CMFE_SOLVER_FULL_MATRICES !<Use fully populated solver matrices.
  CALL cmfe_SolverEquations_EquationsSetAdd(SolverEquations,EquationsSet,EquationsSetIndex,Err)
  CALL cmfe_Problem_SolverEquationsCreateFinish(Problem,Err)

  ! Boundary conditions
  IF(NumberOfSpatialCoordinates==3) THEN !!!!!!!!!!!!!!!!!!!! These are BCs for the 3D case !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    CALL cmfe_BoundaryConditions_Initialise(BoundaryConditions,Err)
    CALL cmfe_SolverEquations_BoundaryConditionsCreateStart(SolverEquations,BoundaryConditions,Err)
    CALL cmfe_GeneratedMesh_SurfaceGet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_BOTTOM_SURFACE,BottomSurfaceNodes,BottomNormalXi, &
      & Err)
    CALL cmfe_GeneratedMesh_SurfaceGet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_LEFT_SURFACE,LeftSurfaceNodes,LeftNormalXi,Err)
    CALL cmfe_GeneratedMesh_SurfaceGet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_RIGHT_SURFACE,RightSurfaceNodes,RightNormalXi,Err)
    CALL cmfe_GeneratedMesh_SurfaceGet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_FRONT_SURFACE,FrontSurfaceNodes,FrontNormalXi,Err)
    !Set x=0 nodes to no x displacment in x. Set x=WIDTH nodes to 0% x displacement
    DO node_idx=1,SIZE(LeftSurfaceNodes,1)
      NodeNumber=LeftSurfaceNodes(node_idx)
      CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
      IF(NodeDomain==ComputationalNodeNumber) THEN
        CALL cmfe_BoundaryConditions_AddNode(BoundaryConditions,DependentField,CMFE_FIELD_U_VARIABLE_TYPE,1,1,NodeNumber,1, &
          & CMFE_BOUNDARY_CONDITION_FIXED,0.0_CMISSRP,Err)
      ENDIF
    ENDDO
    DO node_idx=1,SIZE(RightSurfaceNodes,1)
      NodeNumber=RightSurfaceNodes(node_idx)
      CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
      IF(NodeDomain==ComputationalNodeNumber) THEN
        CALL cmfe_BoundaryConditions_AddNode(BoundaryConditions,DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,1,1,NodeNumber,1, &
          & CMFE_BOUNDARY_CONDITION_FIXED,0.0_CMISSRP,Err)
      ENDIF
    ENDDO
    !Set y=0 nodes to no y displacement
    DO node_idx=1,SIZE(FrontSurfaceNodes,1)
      NodeNumber=FrontSurfaceNodes(node_idx)
      WRITE(*,*) NodeNumber
      CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
      IF(NodeDomain==ComputationalNodeNumber) THEN
        CALL cmfe_BoundaryConditions_AddNode(BoundaryConditions,DependentField,CMFE_FIELD_U_VARIABLE_TYPE,1,1,NodeNumber,2, &
          & CMFE_BOUNDARY_CONDITION_FIXED,0.0_CMISSRP,Err)
      ENDIF
    ENDDO
    !Set z=0 nodes to no z displacement
    DO node_idx=1,SIZE(BottomSurfaceNodes,1)
      NodeNumber=BottomSurfaceNodes(node_idx)
      WRITE(*,*) NodeNumber
      CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
      IF(NodeDomain==ComputationalNodeNumber) THEN
        CALL cmfe_BoundaryConditions_AddNode(BoundaryConditions,DependentField,CMFE_FIELD_U_VARIABLE_TYPE,1,1,NodeNumber,3, &
          & CMFE_BOUNDARY_CONDITION_FIXED,0.0_CMISSRP,Err)
      ENDIF
    ENDDO
    CALL cmfe_SolverEquations_BoundaryConditionsCreateFinish(SolverEquations,Err)
  ELSE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! These are BCs for the 2D case !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    CALL cmfe_BoundaryConditions_Initialise(BoundaryConditions,Err)
    CALL cmfe_SolverEquations_BoundaryConditionsCreateStart(SolverEquations,BoundaryConditions,Err)
    CALL cmfe_GeneratedMesh_SurfaceGet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_FRONT_SURFACE,FrontSurfaceNodes,FrontNormalXi, &
      & Err)
    CALL cmfe_GeneratedMesh_SurfaceGet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_LEFT_SURFACE,LeftSurfaceNodes,LeftNormalXi,Err)
    CALL cmfe_GeneratedMesh_SurfaceGet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_RIGHT_SURFACE,RightSurfaceNodes,RightNormalXi,Err)
    !Set x=0 nodes to no x displacment in x. Set x=WIDTH nodes to 0% x displacement
    DO node_idx=1,SIZE(LeftSurfaceNodes,1)
      NodeNumber=LeftSurfaceNodes(node_idx)
      CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
      IF(NodeDomain==ComputationalNodeNumber) THEN
        CALL cmfe_BoundaryConditions_AddNode(BoundaryConditions,DependentField,CMFE_FIELD_U_VARIABLE_TYPE,1,1,NodeNumber,1, &
          & CMFE_BOUNDARY_CONDITION_FIXED,0.0_CMISSRP,Err)
      ENDIF
    ENDDO
    DO node_idx=1,SIZE(RightSurfaceNodes,1)
      NodeNumber=RightSurfaceNodes(node_idx)
      CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
      IF(NodeDomain==ComputationalNodeNumber) THEN
        CALL cmfe_BoundaryConditions_AddNode(BoundaryConditions,DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,1,1,NodeNumber,1, &
          & CMFE_BOUNDARY_CONDITION_FIXED,0.0_CMISSRP,Err)
      ENDIF
    ENDDO
    !Set y=0 nodes to no y displacement
    DO node_idx=1,SIZE(FrontSurfaceNodes,1)
      NodeNumber=FrontSurfaceNodes(node_idx)
      !WRITE(*,*) NodeNumber
      CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
      IF(NodeDomain==ComputationalNodeNumber) THEN
        CALL cmfe_BoundaryConditions_AddNode(BoundaryConditions,DependentField,CMFE_FIELD_U_VARIABLE_TYPE,1,1,NodeNumber,2, &
          & CMFE_BOUNDARY_CONDITION_FIXED,0.0_CMISSRP,Err)
      ENDIF
    ENDDO
    CALL cmfe_SolverEquations_BoundaryConditionsCreateFinish(SolverEquations,Err)
  ENDIF ! BC-SetUp
  
  ! Checkpoint
  WRITE(*,'(A)') "BCs OK."

  ! Solve multiple timesteps
  CALL cmfe_Fields_Initialise(Fields,Err)
  CALL cmfe_Fields_Create(Region,Fields,Err)
  DO TIMESTEP=1,TIMESTEPS
    WRITE(*,*) "TIME STEP ",TIMESTEP,"/",TIMESTEPS
    ! update BCs - move right surface nodes in positive x-direction
    !BCDISP = 0.1_CMISSRP*WIDTH*(TIMESTEP-1)/(TIMESTEPS-1)
    BCFORCE = BCFORCE_MAX*(TIMESTEP-1)/(TIMESTEPS-1)
    WRITE(*,*) BCFORCE
    
    
    IF(NumberOfSpatialCoordinates==3) THEN ! 3D Case

      SIDE_SIZE = NUMBER_GLOBAL_Z_ELEMENTS*INTERPOLATION_TYPE+1
      TOP_SIZE = NUMBER_GLOBAL_Y_ELEMENTS*INTERPOLATION_TYPE+1
      
      DO col=1,SIDE_SIZE
        DO row=1,TOP_SIZE
           IF((col==1.AND.row==1).OR.(col==1.AND.row==TOP_SIZE).OR. &   ! Corner Node -> Scale BC Force by factor 1/4
             & (col==SIDE_SIZE.AND.row==1).OR.(col==SIDE_SIZE.AND.row==TOP_SIZE)) THEN
             ! transform matrix entries to column
             node_idx = (col-1)*SIDE_SIZE+row
             NodeNumber=RightSurfaceNodes(node_idx)
             CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
             IF(NodeDomain==ComputationalNodeNumber) THEN
               CALL cmfe_Field_ParameterSetUpdateNode(DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
                 & 1,1,NodeNumber,1,BCFORCE/4.0_CMISSRP,Err) ! Apply Force BC
             ENDIF   
             WRITE(*,*) node_idx,NodeNumber 
           ELSEIF(col==1 .OR. col==TOP_SIZE) THEN ! Edge Node (Left/Right) -> Scale BC Force by factor 1/2
             ! transform matrix entries to column
             node_idx = (col-1)*SIDE_SIZE+row
             NodeNumber=RightSurfaceNodes(node_idx)
             CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
             IF(NodeDomain==ComputationalNodeNumber) THEN
               CALL cmfe_Field_ParameterSetUpdateNode(DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
                 & 1,1,NodeNumber,1,BCFORCE/2.0_CMISSRP,Err) ! Apply Force BC
             ENDIF           
           ELSEIF(row==1 .OR. row==SIDE_SIZE) THEN ! Edge Node (Top/Bottom) -> Scale BC
             ! transform matrix entries to column
             node_idx = (col-1)*SIDE_SIZE+row
             NodeNumber=RightSurfaceNodes(node_idx)
             CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
             IF(NodeDomain==ComputationalNodeNumber) THEN
               CALL cmfe_Field_ParameterSetUpdateNode(DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
                 & 1,1,NodeNumber,1,BCFORCE/2.0_CMISSRP,Err) ! Apply Force BC
             ENDIF                
           ELSE ! Inner Node -> No Scaling
             node_idx = (col-1)*SIDE_SIZE+row
             NodeNumber=RightSurfaceNodes(node_idx)
             CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
             IF(NodeDomain==ComputationalNodeNumber) THEN
               CALL cmfe_Field_ParameterSetUpdateNode(DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
                 & 1,1,NodeNumber,1,BCFORCE,Err)
             ENDIF
           ENDIF
        ENDDO
      ENDDO
      
 
    ELSE ! This is the 2D case
      DO node_idx=1,SIZE(RightSurfaceNodes,1)
        NodeNumber=RightSurfaceNodes(node_idx)
        IF(node_idx==1 .OR. node_idx==SIZE(RightSurfaceNodes,1)) THEN
          FORCE=BCFORCE/2.0_CMISSRP
          WRITE(*,*) NodeNumber, node_idx,FORCE
        ELSE
          FORCE=BCFORCE
        ENDIF 
        CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NodeNumber,1,NodeDomain,Err)
        IF(NodeDomain==ComputationalNodeNumber) THEN
          CALL cmfe_Field_ParameterSetUpdateNode(DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
            & 1,1,NodeNumber,1,FORCE,Err)!BCDISP,Err)
        ENDIF
      ENDDO
    ENDIF
    
    
    CALL cmfe_Field_ParameterSetUpdateFinish(DependentField,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,Err)
    ! The actual solve
    CALL cmfe_Problem_Solve(Problem,Err)
    ! Export solution
    IF (TIMESTEP.LE.9) THEN
      WRITE(filename, "(A28,I1)") "results/current_run/Example_",TIMESTEP
      filename=trim(filename)
    ELSEIF (TIMESTEP.LE.99) THEN
      WRITE(filename, "(A28,I2)") "results/current_run/Example_",TIMESTEP
      filename=trim(filename)
    ELSEIF (TIMESTEP.LE.999) THEN
      WRITE(filename, "(A28,I3)") "results/current_run/Example_",TIMESTEP
      filename=trim(filename)
    ELSE
      WRITE(filename, "(A28,I4)") "results/current_run/Example_",TIMESTEP
      filename=trim(filename)
    ENDIF
    CALL cmfe_Fields_NodesExport(Fields,filename,"FORTRAN",Err)
  END DO

  ! Export final solution and topology
  CALL cmfe_Fields_ElementsExport(Fields,"results/current_run/Example","FORTRAN",Err)
  CALL cmfe_Fields_Finalise(Fields,Err)

  ! Finalise
  CALL cmfe_Finalise(Err)
  WRITE(*,'(A)') "Program successfully completed."
  STOP
  
  CONTAINS
  SUBROUTINE HANDLE_ERROR(ERROR_STRING)

    CHARACTER(LEN=*), INTENT(IN) :: ERROR_STRING

    WRITE(*,'(">>ERROR: ",A)') ERROR_STRING(1:LEN_TRIM(ERROR_STRING))
    STOP

  END SUBROUTINE HANDLE_ERROR

END PROGRAM LinearElasticity2DExtensionPlaneStressLagrangeBasis
