import { 
    StyledTextInput, 
    StyledFormArea, 
    StyledFormButton, 
    StyledLabel, 
    Avatar, 
    StyledTitle, 
    colors, 
    ButtonGroup,
    ExtraText,
    TextLink,
    CopyrightText 
} from './../components/Styles'

import Logo from './../assets/logo.svg';

//formik
import { Formik, Form } from 'formik'
import { TextInput } from '../components/FormLib';
import * as Yup from 'yup';

//icons
import { FiMail, FiKey, FiUser, FiCalendar, FiLock } from "react-icons/fi";

import {Oval} from 'react-loader-spinner';

const Signup = () => {
    return (
        <div>
            <StyledFormArea>
                <Avatar image={Logo} />
                <StyledTitle color={colors.theme} size={30}>
                    Member Signup
                </StyledTitle>
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

                    onSubmit={(values, { setSubmitting }) => {
                        console.log(values);
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
                <ExtraText>
                    Have an account? <TextLink to="/login">Login</TextLink>
                </ExtraText>
            </StyledFormArea>
            <CopyrightText>Copyright? No Copy at all</CopyrightText>
        </div>
    )
}

export default Signup;