#define WORKGROUP_SIZE 16
#define N    16
#define MAX_VAL 2147483647



inline void CopyShiftRight(__local int2 *Sort_Reg, int2 new_data, unsigned ID)
{
    #pragma unroll
    for(int i  = N -1  ;  i >= (int) ID ; i--)
    {
        Sort_Reg[i] = Sort_Reg[i -1];
        //printf("CopyShiftRight_id %d \n",Sort_Reg[i]);



    }
    Sort_Reg[ID] = new_data;


}

/* assumes a maximum value of 100*/

__kernel
#ifdef FPGA
//__attribute__((num_compute_units(1)))
//__attribute__((task))
__attribute__((num_simd_work_items(16)))
#endif
__attribute__((reqd_work_group_size(16,1,1)))
void linear_sorter(__global const int2 * restrict input_data, __global int2 * restrict output_data)
{
    //to make it more efficent copy n data into local buffer

    // where actual sorting takes place
    __local int2  sort_reg[N];
    __local unsigned shiftid;

    unsigned local_id =  get_local_id(0);
    unsigned group_offset = get_group_id(0)* N;

    //printf("group_offset %d \n",group_offset);


    //fill with values > max values
    if( local_id == 0)
    {
        //TODO:replace with constant
        for (int i = 0; i < N; i++)
        {
            sort_reg[i] = MAX_VAL;

        }


        //copy first wworkgroup data into reg0

        sort_reg[0] = input_data[group_offset];
        shiftid = -1;
    }


    // ensure that everyone starts from the same place
    //barrier(CLK_LOCAL_MEM_FENCE);

    //if ( local_id == 0)
    //CopyShiftRight(sort_reg, local_id);

    //cycle 2
    //load data
    int2 data;
    //#pragma unroll
    for (int i = 1; i < N; i++)
    {
        data = input_data[group_offset+i];
        barrier(CLK_LOCAL_MEM_FENCE);
        //printf("local_id %d \n",i);


        if(local_id == 0)
        {
            if(data.x < sort_reg[0].x )
            {

                shiftid = 0;
                //printf("local_id %d \n",local_id );



            }


        }
        else if (local_id == N-1)
        {
            if((data.x >= sort_reg[local_id-1].x && data.x <= sort_reg[local_id].x))
            {

                    shiftid = local_id;

            }


        }
        else
        {

            if((data.x >= sort_reg[local_id-1].x && data.x <= sort_reg[local_id + 1].x))
            {

                shiftid = local_id;

            }
        }

        barrier(CLK_LOCAL_MEM_FENCE);
        if (local_id == 0)
        {
            //printf("shiftid %d \n", shiftid);
            CopyShiftRight(sort_reg, data,shiftid);
            //shiftid=419;
        }







    }




        // n cycles complete now write back

    output_data[group_offset+local_id] = sort_reg[local_id];










}
