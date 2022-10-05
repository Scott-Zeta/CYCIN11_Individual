//pages components
import Home from './pages/Home';
import Login from './pages/Login';
import Signup from './pages/Signup';
import Dashboard from './pages/Dashboard';

// sub-pages in rider
import RiderData from './pages/RiderData';
import AddRider from './pages/AddRider';
import RiderList from './pages/RiderList';

//styled components
import { StyledContainer } from './components/Styles';

import {
  BrowserRouter as Router,
  Routes, Route
} from 'react-router-dom';

function App() {
  return (
    <Router>
      <StyledContainer>
        <Routes>
          <Route path='/login' element={<Login />}/>
          <Route path='/signup' element={<Signup />}/>
          <Route path='/dashboard' element = {<Dashboard />}/>
          <Route path='/' element = {<Home />}/>

          <Route path='/riderdata' element = {<RiderData />}/>
          <Route path='/addrider' element = {<AddRider />}/>
          <Route path='/riderlist' element = {<RiderList />}/>
        </Routes>
      </StyledContainer>
    </Router>
  );
}

export default App;
