import React from 'react';
import { NavLink } from 'react-router-dom';

const RiderData = () => {
  return (
    <header>
      <h1>Team Pursuit Strategy Tool</h1>
      <hr />
      <div className="links">
        <NavLink to="/riderlist" className="link" activeclassname="active" exact>
          Rider List
        </NavLink>
        <NavLink to="/addrider" className="link" activeclassname="active">
          Add Rider
        </NavLink>
      </div>
    </header>
  );
};

export default RiderData;