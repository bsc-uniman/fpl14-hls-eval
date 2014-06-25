#define WORKGROUP_SIZE 16


inline void swap3(int *a, int *b)
{

    if (*a > *b)
    {
        int temp = *a;
        *a = *b;
        *b = temp;

    }


}

int median_kernel(__local int *a)
{

    int temp[16];
    #pragma unroll
    for (int i  =0; i < WORKGROUP_SIZE; i++)
    {
        temp[i] = a[i];
    }
    //[[0,1],[2,3],[4,5],[6,7],[8,9],[10,11],[12,13],[14,15]]
    swap3(&temp[0], &temp[1]);
    swap3(&temp[2], &temp[3]);
    swap3(&temp[4], &temp[5]);
    swap3(&temp[6], &temp[7]);
    swap3(&temp[8], &temp[9]);
    swap3(&temp[10], &temp[11]);
    swap3(&temp[12], &temp[13]);
    swap3(&temp[14], &temp[15]);

    //[[0,3],[4,7],[8,11],[12,15]
    swap3(&temp[0], &temp[3]);
    swap3(&temp[4], &temp[7]);
    swap3(&temp[8], &temp[11]);
    swap3(&temp[12], &temp[15]);



    //[1,2],[5,6],[9,10],[13,14]
    swap3(&temp[1], &temp[2]);
    swap3(&temp[5], &temp[6]);
    swap3(&temp[9], &temp[10]);
    swap3(&temp[13], &temp[14]);

    //[[0,1],[2,3],[4,5],[6,7],[8,9],[10,11],[12,13],[14,15]]
    swap3(&temp[0], &temp[1]);
    swap3(&temp[2], &temp[3]);
    swap3(&temp[4], &temp[5]);
    swap3(&temp[6], &temp[7]);
    swap3(&temp[8], &temp[9]);
    swap3(&temp[10], &temp[11]);
    swap3(&temp[12], &temp[13]);
    swap3(&temp[14], &temp[15]);

    //[[0,2],[1,3],[4,6],[5,7], [8,10],[9,11],[12,14],[13,15]]

    swap3(&temp[0], &temp[2]);
    swap3(&temp[1], &temp[3]);
    swap3(&temp[4], &temp[6]);
    swap3(&temp[5], &temp[7]);
    swap3(&temp[8], &temp[10]);
    swap3(&temp[9], &temp[11]);
    swap3(&temp[12], &temp[14]);
    swap3(&temp[13], &temp[15]);

    //[[0,7],[1,6],[2,5],[3,4],[8,15],[9,14],[10,13],[11,12]]
    swap3(&temp[0], &temp[7]);
    swap3(&temp[1], &temp[6]);
    swap3(&temp[2], &temp[5]);
    swap3(&temp[3], &temp[4]);
    swap3(&temp[8], &temp[15]);
    swap3(&temp[9], &temp[14]);
    swap3(&temp[10], &temp[13]);
    swap3(&temp[11], &temp[12]);


    //[[0,1],[2,3],[4,5],[6,7],[8,9],[10,11],[12,13],[14,15]]
    swap3(&temp[0], &temp[1]);
    swap3(&temp[2], &temp[3]);
    swap3(&temp[4], &temp[5]);
    swap3(&temp[6], &temp[7]);
    swap3(&temp[8], &temp[9]);
    swap3(&temp[10], &temp[11]);
    swap3(&temp[12], &temp[13]);
    swap3(&temp[14], &temp[15]);



    //[[0,15],[1,14],[2,13],[3,12],[4,11],[5,10],[6,9],[7,8]]
    swap3(&temp[0], &temp[15]);
    swap3(&temp[1], &temp[14]);
    swap3(&temp[2], &temp[13]);
    swap3(&temp[3], &temp[12]);
    swap3(&temp[4], &temp[11]);
    swap3(&temp[5], &temp[10]);
    swap3(&temp[6], &temp[9]);
    swap3(&temp[7], &temp[8]);
    //[[0,4],[1,5],[2,6],[3,7],[8,12],[9,13],[10,14],[11,15]]
    swap3(&temp[0], &temp[4]);
    swap3(&temp[1], &temp[5]);
    swap3(&temp[2], &temp[6]);
    swap3(&temp[3], &temp[7]);
    swap3(&temp[8], &temp[12]);
    swap3(&temp[9], &temp[13]);
    swap3(&temp[10], &temp[14]);
    swap3(&temp[11], &temp[15]);
    //[[0,2],[1,3],[4,6],[5,7],[8,10],[9,11],[12,14],[13,15]]
    swap3(&temp[0], &temp[2]);
    swap3(&temp[1], &temp[3]);
    swap3(&temp[4], &temp[6]);
    swap3(&temp[5], &temp[7]);
    swap3(&temp[8], &temp[10]);
    swap3(&temp[9], &temp[11]);
    swap3(&temp[12], &temp[14]);
    swap3(&temp[13], &temp[15]);
    //[[0,1],[2,3],[4,5],[6,7],[8,9],[10,11],[12,13],[14,15]]

    swap3(&temp[0], &temp[1]);
    swap3(&temp[2], &temp[3]);
    swap3(&temp[4], &temp[5]);
    swap3(&temp[6], &temp[7]);
    swap3(&temp[8], &temp[9]);
    swap3(&temp[10], &temp[11]);
    swap3(&temp[12], &temp[13]);
    swap3(&temp[14], &temp[15]);


/*    for (int i =0 ; i < 8; i++)
    {
        printf("id:%d value:%d \n", i,temp[i].x );
    }*/

    return (temp[7] +temp[8])/2;
}

__kernel
#ifdef FPGA
//__attribute__((num_compute_units(1)))
//__attribute__((task))
#endif
__attribute__((reqd_work_group_size(WORKGROUP_SIZE,1,1)))
void medain_operator(__global int* restrict  input_data,  __global int* restrict  output_data)
{

    const int local_id = get_local_id(0);        // ID within the workgroup
    const int global_id = get_global_id(0);      // ID within the NDRange

      //printf("global:%d local:%d \n", global_id, local_id );


    /*alocate memory for input with 15 extra locations that will be filled from the next workgroup. The end of the global input data shoul be paded with extra 15 locations, at the back and front, to avoid memory accesses error*/
    __local int local_input_data[WORKGROUP_SIZE +15];

   if (local_id < 15)
   {
    local_input_data[local_id] = input_data[global_id];
   }
    //printf("global:%d local:%d data:%d \n", global_id, local_id,local_input_data[local_id].x);

    /*  Copying "WORKGROUP_SIZE" inputs into the local buffer while reserving the first seven local buffer locations for the last two inputs from the previous workgroup. Copying from global index +7 because the start of the buffer has two padded elements. */
    local_input_data[local_id+15] = input_data[global_id+15];

    //printf("max lid: %d   max gid: %d \n", local_id+7, global_id+7);

    barrier(CLK_LOCAL_MEM_FENCE);
    //if (global_id >120 )
    //{
      //  for (int i =0 ; i < WORKGROUP_SIZE +15; i++)
        //{
         //   printf("id:%d value:%d \n", global_id,local_input_data[i].x );
        //}
    //}


    if(global_id > 14)
    {
        output_data[global_id] = median_kernel(&local_input_data[local_id]);
        //printf("global:%d local:%d \n", global_id, local_id );
        // if (global_id > 120)
        //     printf("global:%d local:%d  median:%d \n", global_id, local_id,output_data[global_id] );
    }









    //actual sorter
    //sorting_kernel(&temp);













}
