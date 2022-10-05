import React from 'react';
import RiderForm from './RiderForm';

const AddRider = () => {
  const handleOnSubmit = (rider) => {
    console.log(rider);
  };

  return (
    <React.Fragment>
      <RiderForm handleOnSubmit={handleOnSubmit} />
    </React.Fragment>
  );
};

export default AddRider;