import React from 'react';
import RiderData from './RiderData';

const RiderList = ({ riderInfo }) => {
  return (
    <div>
      <h2>Team Members</h2>
      <table style={{ border:"1px solid black"}}>
        <tr>
          <th style={{ border:"1px solid black", padding: "5px"}}> Name/ID </th>
          <th style={{ border:"1px solid black", padding: "5px"}}>Mass(KG)</th>
          <th style={{ border:"1px solid black", padding: "5px"}}>CDA Seated(m^2)</th>
          <th style={{ border:"1px solid black", padding: "5px"}}>Seat Heigh(m)</th>
          <th style={{ border:"1px solid black", padding: "5px"}}>Initial Power Turn(W)</th>
          <th style={{ border:"1px solid black", padding: "5px"}}>CP(W)</th>
          <th style={{ border:"1px solid black", padding: "5px"}}>W'(J)</th>
        </tr>
        {riderInfo.map((p, i) => <RiderData key={i} rider={p} />)}
      </table>
    </div>
  )
};

export default RiderList;