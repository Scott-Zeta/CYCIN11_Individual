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
                        email: "",
                        password: "",
                        repeatPassword:"",
                        dateOfBirth: "",
                        name:""
                    }}

                    //validation
                    validationSchema = {
                        Yup.object({
                            email: Yup.string().email("Invalid email address")
                            .required("Required"),
                            password: Yup.string()
                            .min(8, "Too short password")
                            .max(30, "Too long password")
                            .required("Required"),
                            name: Yup.string().required("Required"),
                            dateOfBirth: Yup.date().required("Required"),
                            repeatPassword: Yup.string().required("Required").oneOf([Yup.ref("password"), null],"Password must be matched.")
                        })
                    }

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
                                label="Full Name"
                                icon={<FiUser />}
                            />
                            <TextInput
                                name="email"
                                type="text"
                                label="Email Address"
                                placeholder="address@example.com"
                                icon={<FiMail />}
                            />
                            <TextInput
                                name="dateOfBirth"
                                type="date"
                                label="Date of Birth"
                                icon={<FiCalendar />}
                            />
                            <TextInput
                                name="password"
                                type="password"
                                label="Password"
                                icon={<FiLock />}
                            />
                            <TextInput
                                name="repeatPassword"
                                type="password"
                                label="Repeat Password"
                                icon={<FiKey />}
                            />
                            <ButtonGroup>
                                {!isSubmitting && <StyledFormButton type="submit">
                                    Signup
                                </StyledFormButton>}

                                {isSubmitting && (
                                    <Oval
                                        color = {colors.theme}
                                        height = {50}
                                        width = {50}
                                    />
                                )}
                            </ButtonGroup>
                        </Form>
                    )}
                </Formik>
            </StyledFormArea>
        </div>
    );
}

export default Dashboard;