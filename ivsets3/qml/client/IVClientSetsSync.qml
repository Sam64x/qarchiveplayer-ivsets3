import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0

Window
{
    id:root
    width: 640
    height: 480
    visible: false
    modality: Qt.ApplicationModal
    color: "#d9d9d9"
    title: "Окно синхронизации наборов"
    IVCustomSets
    {
        id:customSets
    }






}
