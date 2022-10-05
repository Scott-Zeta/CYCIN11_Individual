import React, { useState } from 'react';
import { Form, Button } from 'react-bootstrap';
import { v4 as uuidv4 } from 'uuid';

const RiderForm = (props) => {
  const [rider, setRider] = useState({
    ridername: props.rider ? props.rider.ridername : '',
    yearofbirth: props.rider ? props.rider.yearofbirth : '',
    gender: props.rider ? props.rider.gender : '',
    date: props.rider ? props.rider.date : ''
  });

  const [errorMsg, setErrorMsg] = useState('');
  const { ridername, yearofbirth, gender } = rider;

  const handleOnSubmit = (event) => {
    event.preventDefault();
    const values = [ridername, yearofbirth, gender];
    let errorMsg = '';

    const allFieldsFilled = values.every((field) => {
      const value = `${field}`.trim();
      return value !== '' && value !== '0';
    });

    if (allFieldsFilled) {
      const rider = {
        id: uuidv4(),
        ridername,
        yearofbirth,
        gender,
        date: new Date()
      };
      props.handleOnSubmit(rider);
    } else {
      errorMsg = 'Please fill out all the fields.';
    }
    setErrorMsg(errorMsg);
  };

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    switch (name) {
      case 'yearofbirth':
        if (value === '' || parseInt(value) === +value) {
          setRider((prevState) => ({
            ...prevState,
            [name]: value
          }));
        }
        break;
      default:
        setRider((prevState) => ({
          ...prevState,
          [name]: value
        }));
    }
  };

  return (
    <div className="main-form">
      {errorMsg && <p className="errorMsg">{errorMsg}</p>}
      <Form onSubmit={handleOnSubmit}>
        <Form.Group controlId="name">
          <Form.Label>Rider Name</Form.Label>
          <Form.Control
            className="input-control"
            type="text"
            name="ridername"
            value={ridername}
            placeholder="Enter the name of rider"
            onChange={handleInputChange}
          />
        </Form.Group>
        <Form.Group controlId="yearofbirth">
          <Form.Label>Year of Birth</Form.Label>
          <Form.Control
            className="input-control"
            type="number"
            name="yearofbirth"
            value={yearofbirth}
            placeholder="Enter rider's year of birth"
            onChange={handleInputChange}
          />
        </Form.Group>
        <Form.Group controlId="gender">
          <Form.Label>Gender</Form.Label>
          <Form.Control
            className="input-control"
            type="text"
            name="gender"
            value={gender}
            placeholder="Enter rider's gender"
            onChange={handleInputChange}
          />
        </Form.Group>
        <Button variant="primary" type="submit" className="submit-btn">
          Submit
        </Button>
      </Form>
    </div>
  );
};

export default RiderForm;