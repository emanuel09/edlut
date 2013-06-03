/***************************************************************************
 *                           EgidioGranuleCell_TimeDriven_GPU.cu           *
 *                           -------------------                           *
 * copyright            : (C) 2013 by Francisco Naveros                    *
 * email                : fnaveros@atc.ugr.es                              *
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "../../include/neuron_model/EgidioGranuleCell_TimeDriven_GPU.h"
#include "../../include/neuron_model/EgidioGranuleCell_TimeDriven_GPU2.h"
#include "../../include/neuron_model/VectorNeuronState.h"
#include "../../include/neuron_model/VectorNeuronState_GPU.h"

#include <iostream>
#include <cmath>
#include <string>


#include "../../include/spike/EDLUTFileException.h"
#include "../../include/spike/Neuron.h"
#include "../../include/spike/InternalSpike.h"
#include "../../include/spike/PropagatedSpike.h"
#include "../../include/spike/Interconnection.h"

#include "../../include/simulation/Utils.h"

#include "../../include/cudaError.h"
//Library for CUDA
#include <cutil_inline.h>

void EgidioGranuleCell_TimeDriven_GPU::LoadNeuronModel(string ConfigFile) throw (EDLUTFileException){
	FILE *fh;
	long Currentline = 0L;
	fh=fopen(ConfigFile.c_str(),"rt");
	if(fh){

		Currentline=1L;
		skip_comments(fh,Currentline);
		if(fscanf(fh,"%f",&this->gMAXNa_f)==1){
			skip_comments(fh,Currentline);

			if (fscanf(fh,"%f",&this->gMAXNa_r)==1){
				skip_comments(fh,Currentline);

				if(fscanf(fh,"%f",&this->gMAXNa_p)==1){
					skip_comments(fh,Currentline);

					if(fscanf(fh,"%f",&this->gMAXK_V)==1){
						skip_comments(fh,Currentline);

						if(fscanf(fh,"%f",&this->gMAXK_A)==1){
							skip_comments(fh,Currentline);

							if(fscanf(fh,"%f",&this->gMAXK_IR)==1){
								skip_comments(fh,Currentline);

								if(fscanf(fh,"%f",&this->gMAXK_Ca)==1){
									skip_comments(fh,Currentline);

									if(fscanf(fh,"%f",&this->gMAXCa)==1){
										skip_comments(fh,Currentline);

										if(fscanf(fh,"%f",&this->gMAXK_sl)==1){
											skip_comments(fh,Currentline);

											this->InitialState = (VectorNeuronState_GPU *) new VectorNeuronState_GPU(17);

										}
//NEW CODE------------------------------------------------------------------------------									
										else {
											throw EDLUTFileException(13,60,3,1,Currentline);
										}
									} else {
										throw EDLUTFileException(13,61,3,1,Currentline);
									}
								} else {
									throw EDLUTFileException(13,62,3,1,Currentline);
								}
							} else {
								throw EDLUTFileException(13,63,3,1,Currentline);
							}
						} else {
							throw EDLUTFileException(13,64,3,1,Currentline);
						}
					} else {
						throw EDLUTFileException(13,65,3,1,Currentline);
					}
				} else {
					throw EDLUTFileException(13,66,3,1,Currentline);
				}
			} else {
				throw EDLUTFileException(13,67,3,1,Currentline);
			}
		} else {
			throw EDLUTFileException(13,68,3,1,Currentline);
		}
//-------------------------------------------------------------------------------------

		//INTEGRATION METHOD
		this->integrationMethod_GPU=LoadIntegrationMethod_GPU::loadIntegrationMethod_GPU(fh, &Currentline, N_NeuronStateVariables, N_DifferentialNeuronState, N_TimeDependentNeuronState);

		//TIME DRIVEN STEP
		this->TimeDrivenStep_GPU = LoadTimeEvent_GPU::loadTimeEvent_GPU(fh, &Currentline);
	}
}

void EgidioGranuleCell_TimeDriven_GPU::SynapsisEffect(int index, VectorNeuronState_GPU * state, Interconnection * InputConnection){

	switch (InputConnection->GetType()){
		case 0: {
			state->AuxStateCPU[0*state->GetSizeState() + index]+=1e-9*InputConnection->GetWeight();
			break;
		}case 1:{
			state->AuxStateCPU[1*state->GetSizeState() + index]+=1e-9*InputConnection->GetWeight();
			break;
		}
	}
}



EgidioGranuleCell_TimeDriven_GPU::EgidioGranuleCell_TimeDriven_GPU(string NeuronTypeID, string NeuronModelID): TimeDrivenNeuronModel_GPU(NeuronTypeID, NeuronModelID), gMAXNa_f(0), gMAXNa_r(0), gMAXNa_p(0), gMAXK_V(0), gMAXK_A(0), gMAXK_IR(0), gMAXK_Ca(0),
		gMAXCa(0), gMAXK_sl(0), gLkg1(5.68e-5), gLkg2(2.17e-5), VNa(87.39), VK(-84.69), VLkg1(-58), VLkg2(-65), V0_xK_Ai(-46.7),
		K_xK_Ai(-19.8), V0_yK_Ai(-78.8), K_yK_Ai(8.4), V0_xK_sli(-30), B_xK_sli(6), F(96485.309), A(1e-04), d(0.2), betaCa(1.5),
		Ca0(1e-04), R(8.3134), cao(2), Cm(1.0e-3), temper(30), Q10_20 ( pow(3,((temper-20)/10))), Q10_22 ( pow(3,((temper-22)/10))),
		Q10_30 ( pow(3,((temper-30)/10))), Q10_6_3 ( pow(3,((temper-6.3)/10))),	/*I_inj_abs(11e-12)*/I_inj_abs(0),
		I_inj(-I_inj_abs*1000/299.26058e-8), eexc(0.0), einh(-80), texc(0.5), tinh(10), vthr(-0.25){
}

EgidioGranuleCell_TimeDriven_GPU::~EgidioGranuleCell_TimeDriven_GPU(void){
	DeleteClassGPU();
}

void EgidioGranuleCell_TimeDriven_GPU::LoadNeuronModel() throw (EDLUTFileException){
	this->LoadNeuronModel(this->GetModelID()+".cfg");
}


VectorNeuronState * EgidioGranuleCell_TimeDriven_GPU::InitializeState(){
	return this->GetVectorNeuronState();
}


InternalSpike * EgidioGranuleCell_TimeDriven_GPU::ProcessInputSpike(PropagatedSpike *  InputSpike){
	Interconnection * inter = InputSpike->GetSource()->GetOutputConnectionAt(InputSpike->GetTarget());

	Neuron * TargetCell = inter->GetTarget();

	int indexGPU =TargetCell->GetIndex_VectorNeuronState();

	VectorNeuronState_GPU * state = (VectorNeuronState_GPU *) this->InitialState;

	// Add the effect of the input spike
	this->SynapsisEffect(inter->GetTarget()->GetIndex_VectorNeuronState(), state, inter);

	return 0;
}



__global__ void EgidioGranuleCell_TimeDriven_GPU_UpdateState(int size, int offset, TimeDrivenNeuronModel_GPU2 ** timeDrivenNeuronModel_GPU2, float * AuxStateGPU, float * StateGPU, double * LastUpdateGPU, double * LastSpikeTimeGPU, bool * InternalSpikeGPU, int SizeStates, double CurrentTime){
	int index = offset + blockIdx.x * blockDim.x + threadIdx.x;
	while (index < (offset + size) && index<SizeStates){
		(*timeDrivenNeuronModel_GPU2)->UpdateState(index, AuxStateGPU, StateGPU, LastUpdateGPU, LastSpikeTimeGPU, InternalSpikeGPU, SizeStates, CurrentTime);
		index+=blockDim.x*gridDim.x;
	}
}
		
bool EgidioGranuleCell_TimeDriven_GPU::UpdateState(int index, VectorNeuronState * State, double CurrentTime){
	
	VectorNeuronState_GPU *state = (VectorNeuronState_GPU *) State;

	cudaDeviceProp prop;
	HANDLE_ERROR(cudaGetDeviceProperties( &prop, 0 ));
	if(prop.canMapHostMemory && true){
		int size=N_block*N_thread;
		int offset=0;
		while (offset<state->SizeStates){
			EgidioGranuleCell_TimeDriven_GPU_UpdateState<<<N_block,N_thread>>>(size,offset,timeDrivenNeuronModel_GPU2, state->AuxStateGPU, state->VectorNeuronStates_GPU, state->LastUpdateGPU, state->LastSpikeTimeGPU, state->InternalSpikeGPU, state->SizeStates, CurrentTime);
			offset+=size;
		}
	}else{
		HANDLE_ERROR(cudaMemcpy(state->AuxStateGPU,state->AuxStateCPU,4*state->SizeStates*sizeof(float),cudaMemcpyHostToDevice));
		int size=N_block*N_thread*2;
		int offset=0;
		while (offset<state->SizeStates){
			EgidioGranuleCell_TimeDriven_GPU_UpdateState<<<N_block,N_thread>>>(size, offset, timeDrivenNeuronModel_GPU2, state->AuxStateGPU, state->VectorNeuronStates_GPU, state->LastUpdateGPU, state->LastSpikeTimeGPU, state->InternalSpikeGPU, state->SizeStates, CurrentTime);
			offset+=size;
		}
		HANDLE_ERROR(cudaMemcpy(state->InternalSpikeCPU,state->InternalSpikeGPU,state->SizeStates*sizeof(bool),cudaMemcpyDeviceToHost));
	}


	if(this->GetVectorNeuronState()->Get_Is_Monitored()){
		HANDLE_ERROR(cudaMemcpy(state->VectorNeuronStates,state->VectorNeuronStates_GPU,state->GetNumberOfVariables()*state->SizeStates*sizeof(float),cudaMemcpyDeviceToHost));
		HANDLE_ERROR(cudaMemcpy(state->LastUpdate,state->LastUpdateGPU,state->SizeStates*sizeof(double),cudaMemcpyDeviceToHost));
		HANDLE_ERROR(cudaMemcpy(state->LastSpikeTime,state->LastSpikeTimeGPU,state->SizeStates*sizeof(double),cudaMemcpyDeviceToHost));
	}

	HANDLE_ERROR(cudaEventRecord(stop, 0)); 
	HANDLE_ERROR(cudaEventSynchronize(stop));

	memset(state->AuxStateCPU,0,N_TimeDependentNeuronState*state->SizeStates*sizeof(float));

	return false;

}


ostream & EgidioGranuleCell_TimeDriven_GPU::PrintInfo(ostream & out){
	return out;
}	


void EgidioGranuleCell_TimeDriven_GPU::InitializeStates(int N_neurons){

	VectorNeuronState_GPU * state = (VectorNeuronState_GPU *) this->InitialState;

	//Initial State
	float xNa_f=0.00047309535;
	float yNa_f=1.0;
	float xNa_r=0.00013423511;
	float yNa_r=0.96227829;
	float xNa_p=0.00050020111;
	float xK_V=0.010183001;
	float xK_A=0.15685486;
	float yK_A=0.53565367;
	float xK_IR=0.37337035;
	float xK_Ca=0.00012384122;
	float xCa=0.0021951104;
	float yCa=0.89509747;
	float xK_sl=0.00024031171;
	float Ca=Ca0;
	float V=-80.0;
	float gexc=0.0;
	float ginh=0.0;

	//Initialize neural state variables.
	float initialization[] = {xNa_f,yNa_f,xNa_r,yNa_r,xNa_p,xK_V,xK_A,yK_A,xK_IR,xK_Ca,xCa,yCa,xK_sl,Ca,V,gexc,ginh};
	state->InitializeStatesGPU(N_neurons, initialization, N_TimeDependentNeuronState);

	//INITIALIZE CLASS IN GPU
	this->InitializeClassGPU(N_neurons);
}


__global__ void EgidioGranuleCell_TimeDriven_GPU2_InitializeClassGPU(TimeDrivenNeuronModel_GPU2 ** timeDrivenNeuronModel_GPU2,
		float gMAXNa_f, float gMAXNa_r, float gMAXNa_p, float gMAXK_V,
		float gMAXK_A,float gMAXK_IR,float gMAXK_Ca,float gMAXCa,float gMAXK_sl, char const* integrationName, int N_neurons, int Total_N_thread, void ** Buffer_GPU){
	if(blockIdx.x==0 && threadIdx.x==0){
		(*timeDrivenNeuronModel_GPU2) = (EgidioGranuleCell_TimeDriven_GPU2 *) new EgidioGranuleCell_TimeDriven_GPU2(gMAXNa_f, gMAXNa_r, gMAXNa_p, gMAXK_V,
			gMAXK_A,gMAXK_IR,gMAXK_Ca,gMAXCa,gMAXK_sl,integrationName, N_neurons, Total_N_thread, Buffer_GPU);
	}
}


void EgidioGranuleCell_TimeDriven_GPU::InitializeClassGPU(int N_neurons){
	cudaMalloc(&timeDrivenNeuronModel_GPU2, sizeof(TimeDrivenNeuronModel_GPU2 **));
	
	char * integrationNameGPU;
	cudaMalloc((void **)&integrationNameGPU,32*4);
	HANDLE_ERROR(cudaMemcpy(integrationNameGPU,integrationMethod_GPU->GetType(),32*4,cudaMemcpyHostToDevice));

	cudaDeviceProp prop;
	HANDLE_ERROR(cudaGetDeviceProperties( &prop, 0 ));	
	this->N_thread = 128;
	this->N_block=prop.multiProcessorCount*4;
	if((N_neurons+N_thread-1)/N_thread < N_block){
		N_block = (N_neurons+N_thread-1)/N_thread;
	}
	int Total_N_thread=N_thread*N_block;

	integrationMethod_GPU->InitializeMemoryGPU(N_neurons, Total_N_thread);

	
	EgidioGranuleCell_TimeDriven_GPU2_InitializeClassGPU<<<1,1>>>(timeDrivenNeuronModel_GPU2,gMAXNa_f, gMAXNa_r, gMAXNa_p, gMAXK_V,
			gMAXK_A,gMAXK_IR,gMAXK_Ca,gMAXCa,gMAXK_sl,integrationNameGPU, N_neurons,Total_N_thread, integrationMethod_GPU->Buffer_GPU);

	cudaFree(integrationNameGPU);
}



__global__ void EgidioGranuleCell_TimeDriven_GPU_DeleteClassGPU(TimeDrivenNeuronModel_GPU2 ** timeDrivenNeuronModel_GPU2){
	if(blockIdx.x==0 && threadIdx.x==0){
		delete (*timeDrivenNeuronModel_GPU2); 
	}
}

void EgidioGranuleCell_TimeDriven_GPU::DeleteClassGPU(){
    EgidioGranuleCell_TimeDriven_GPU_DeleteClassGPU<<<1,1>>>(timeDrivenNeuronModel_GPU2);
    cudaFree(timeDrivenNeuronModel_GPU2);
}