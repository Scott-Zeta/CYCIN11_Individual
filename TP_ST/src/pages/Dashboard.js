import { StyledTitle, StyledSubTitle, Avatar, StyledButton, ButtonGroup, StyledFormArea, colors, StyledFormButton, StyledUserInfo } from "../components/Styles";

//formik
import { Formik, Form } from 'formik'
import { TextInput } from '../components/FormLib';
import * as Yup from 'yup';

//icon and button
import { FiMail, FiKey, FiUser, FiCalendar, FiLock } from "react-icons/fi";
import {Oval} from 'react-loader-spinner';

import { signupUser } from '../auth/actions/userActions';
import { useNavigate } from "react-router-dom";

//logo
import Logo from "../assets/logo.svg";

const Dashboard = () => {
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
                    Welcome, User      
                    <StyledButton to="#" color={colors.theme} border={colors.dark3}>Logout</StyledButton>
                </StyledUserInfo>

                <Formik
                    initialValues={{
                        name:"",
                        mass:"",
                        CDA_Seated:"",
                        seat_height:"",
                        init_p_t:"",
                        cp:"",
                        w:""
                    }}

                    //validation
                    // validationSchema = {
                    //     Yup.object({
                    //         email: Yup.string().email("Invalid email address")
                    //         .required("Required"),
                    //         password: Yup.string()
                    //         .min(8, "Too short password")
                    //         .max(30, "Too long password")
                    //         .required("Required"),
                    //         name: Yup.string().required("Required"),
                    //         dateOfBirth: Yup.date().required("Required"),
                    //         repeatPassword: Yup.string().required("Required").oneOf([Yup.ref("password"), null],"Password must be matched.")
                    //     })
                    // }

                    onSubmit={(values, { setSubmitting,setFiledError }) => {
                        console.log(values);
                        signupUser(values,history,setFiledError,setSubmitting)
                    }}
                >
                    {({isSubmitting}) => (
                        <Form>
                            <TextInput
                                name="name"
                                type="text"
                                label="Name/ID"
                                icon={<FiUser />}
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
                                    Signup
                                </StyledFormButton>}
                            </ButtonGroup>
                        </Form>
                    )}
                </Formik>
            </StyledFormArea>
        </div>
    );
}

export default Dashboard;