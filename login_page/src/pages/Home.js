import { StyledTitle, StyledSubTitle, Avatar } from "../components/Styles";

//logo
import Logo from "../assets/logo.svg";

const Home = () => {
    return (
        <div>
            <div>
                <Avatar image={Logo} />
            </div>
            <StyledTitle size={65}>
                Welcome to Team Pursuit Strategy Tools!
            </StyledTitle>
            <StyledSubTitle size={27}>
                Feel free to explore
            </StyledSubTitle>
        </div>
    );
}

export default Home;