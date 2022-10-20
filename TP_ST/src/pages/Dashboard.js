import { StyledTitle, StyledSubTitle, Avatar, StyledButton, ButtonGroup, StyledFormArea, colors, StyledFormButton, StyledUserInfo } from "../components/Styles";

//formik
import { Formik, Form } from 'formik'
import { TextInput } from '../components/FormLib';
import * as Yup from 'yup';

//icon and button
import { FiMail, FiKey, FiUser, FiCalendar, FiLock } from "react-icons/fi";

import { useNavigate } from "react-router-dom";

//logo
import Logo from "../assets/logo.svg";
import { useState } from "react";

//sub components
import RiderList from "./RiderList";

//authetic & redux
import {connect} from 'react-redux';
import { logoutUser } from "../auth/actions/userActions";

const Dashboard = ({logoutUser,user}) => {
    const [riderInfo, setInfo] = useState([]);
    const history = useNavigate();
    return (
        <div>
            <div style={{
                position: "absolute",
                top: 0,
                left: 0,
                backgroundColor: "transparent",
                width: "100%",
                padding: "15px",
                display: "flex",
                justifyContent: "flex-start",
            }}>
                <Avatar image={Logo} />
            </div>

            <StyledFormArea bg={colors.light2}>
                <StyledUserInfo size={50} color={colors.dark2}>
                    Welcome, {user.name}
                    <StyledButton to="#" color={colors.theme} border={colors.dark3} onClick={() => logoutUser(history)}>Logout</StyledButton>
                </StyledUserInfo>

                <Formik
                    initialValues={{
                        name: "",
                        mass: "",
                        CDA_Seated: "",
                        seat_height: "",
                        init_p_t: "",
                        cp: "",
                        w: ""
                    }}

                    //validation
                    validationSchema={
                        Yup.object({
                            name: Yup.string().required("Required"),
                            mass: Yup.number().positive("Must be positive!").required("Required"),
                            CDA_Seated: Yup.number().positive("Must be positive!").required("Required"),
                            seat_height: Yup.number().positive("Must be positive!").required("Required"),
                            init_p_t: Yup.number().positive("Must be positive!").required("Required"),
                            cp: Yup.number().positive("Must be positive!").required("Required"),
                            w: Yup.number().positive("Must be positive!").required("Required")
                        })
                    }

                    onSubmit={(values) => {
                        console.log(values);
                        setInfo(riderInfo.concat(values));
                        console.log(riderInfo);
                    }}
                >
                    {() => (
                        <Form>
                            <TextInput
                                name="name"
                                type="text"
                                label="Name/ID"
                            />
                            <TextInput
                                name="mass"
                                type="number"
                                label="Mass(KG)"
                            />
                            <TextInput
                                name="CDA_Seated"
                                type="number"
                                label="CDA Seated(m^2)"
                            />
                            <TextInput
                                name="seat_height"
                                type="number"
                                label="Seat Heigh(m)"
                            />
                            <TextInput
                                name="init_p_t"
                                type="number"
                                label="Initial Power Turn(W)"
                            />
                            <TextInput
                                name="cp"
                                type="number"
                                label="CP(W)"
                            />
                            <TextInput
                                name="w"
                                type="number"
                                label="W'(J)"
                            />
                            <ButtonGroup>
                                {<StyledFormButton type="submit">
                                    Save Profile
                                </StyledFormButton>}
                            </ButtonGroup>
                        </Form>
                    )}
                </Formik>
                <RiderList riderInfo={riderInfo}/>
            </StyledFormArea>
        </div>
    );
}

const mapStateToProps = ({session}) => ({
    user: session.user
})

export default connect(mapStateToProps,{logoutUser}) (Dashboard);