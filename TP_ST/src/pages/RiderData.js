import React from 'react';

const RiderData = ({rider}) =>{
  return(
    <tbody>
    <tr>
      <td>{rider.name}</td>     
      <td>{rider.mass}</td>
      <td>{rider.CDA_Seated}</td>
      <td>{rider.seat_height}</td>
      <td>{rider.init_p_t}</td>
      <td>{rider.cp}</td>
      <td>{rider.w}</td>
    </tr>
    </tbody>
  )
}

export default RiderData;