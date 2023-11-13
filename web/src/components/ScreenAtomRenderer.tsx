import {useMainLayout} from "@/components/layouts/MainLayout";
import {Active_Page} from "@/global/types";
import HomeScreen from "@/pages/HomeScreen";
import NetworkScreen from "@/pages/NetworkScreen";
import LobbyScreen from "@/pages/LobbyScreen";
import GameLayout from "@/components/layouts/GameLayout";
import GamePlayScreen from "@/pages/GamePlayScreen";

export default function ScreenAtomRenderer() {
    const {currentPage} = useMainLayout()

    function ConditionedScreen() {
        switch (currentPage) {
            case Active_Page.Network: {
                return <NetworkScreen/>
            }
            case Active_Page.Lobby: {
                return (
                    <GameLayout>
                        <LobbyScreen/>
                    </GameLayout>
                )
            }
            case Active_Page.Gameplay: {
                return (
                    <GameLayout>
                        <GamePlayScreen/>
                    </GameLayout>
                )
            }
            case Active_Page.Home:
            default: {
                return <HomeScreen/>
            }
        }
    }

    return <ConditionedScreen/>
}
