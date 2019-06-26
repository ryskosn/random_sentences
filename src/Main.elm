module Main exposing (main)

import Array
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D exposing (Decoder)
import Random
import Spreadsheet exposing (jsonAPIUrl)
import Task
import Time


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type FetchState
    = NotYet
    | Fetching
    | Success Sheets
    | Failure Http.Error


type alias Model =
    { fetchState : FetchState
    , category : String
    , showAllState : Bool
    , sheets : Sheets
    , sentences : List Sentence
    , index : Int
    , sentence : Sentence
    , shufflingState : Bool
    , count : Int
    , showedSentences : List Sentence
    , restSentences : List Sentence
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { fetchState = NotYet
      , category = ""
      , showAllState = False
      , sheets = []
      , sentences = List.singleton sentenceDefault
      , index = 0
      , sentence = sentenceDefault
      , shufflingState = False
      , count = 0
      , showedSentences = []
      , restSentences = []
      }
    , Cmd.none
    )


sentenceDefault : Sentence
sentenceDefault =
    { id = ""
    , sentence = "Select a category."
    , note = ""
    }


categoryDefault : String
categoryDefault =
    "---"



-- UPDATE


type Msg
    = FetchSentences
    | GotSentences (Result Http.Error Sheets)
    | Change String
    | ShowAllSentences
    | Pick
    | GetIndex Int
    | Tick Time.Posix
    | CheckCount Time.Posix
    | Shuffle Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchSentences ->
            ( { model
                | fetchState = Fetching
                , category = categoryDefault
                , showAllState = False
              }
            , getSentences
            )

        GotSentences result ->
            case result of
                Ok data ->
                    ( { model
                        | fetchState = Success data
                        , sheets = data
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model | fetchState = Failure error }
                    , Cmd.none
                    )

        Change sheetName ->
            ( { model
                | category = sheetName
                , showAllState = False
                , sentences = getSentencesBySheetName model.sheets sheetName
                , showedSentences = []
              }
            , Cmd.none
            )

        ShowAllSentences ->
            ( { model | showAllState = True }
            , Cmd.none
            )

        Pick ->
            ( { model | shufflingState = True }
            , Random.generate GetIndex (randomIndex (getSource model))
            )

        GetIndex i ->
            ( { model | index = i }
            , Cmd.none
            )

        Tick newTime ->
            let
                c =
                    if model.shufflingState then
                        model.count + 1

                    else
                        model.count
            in
            ( { model | count = c }
            , Task.perform CheckCount Time.now
            )

        CheckCount newTime ->
            ( setSentence model
            , Task.perform Shuffle Time.now
            )

        Shuffle newTime ->
            ( shuffleSentence model
            , Cmd.none
            )


randomIndex : List Sentence -> Random.Generator Int
randomIndex sentences =
    Random.int 0 <|
        if List.length sentences > 1 then
            List.length sentences - 1

        else
            0


pickByIndex : List Sentence -> Int -> Sentence
pickByIndex sentences index =
    let
        arr =
            Array.fromList sentences
    in
    Array.get index arr
        |> Maybe.withDefault sentenceDefault


getSource : Model -> List Sentence
getSource model =
    let
        -- isNotShowed : Sentence -> Bool
        isNotShowed sentence =
            not (List.member sentence model.showedSentences)
    in
    let
        rest =
            List.filter isNotShowed model.sentences
    in
    if List.isEmpty model.showedSentences then
        model.sentences

    else
        rest


setSentence : Model -> Model
setSentence model =
    if model.count == maxCount then
        -- random に選んだ index に該当する sentence をセットする
        let
            s =
                pickByIndex (getSource model) model.index
        in
        { model
            | shufflingState = False
            , count = 0
            , sentence = s
            , showedSentences = s :: model.showedSentences
        }

    else
        model


resetStatus : Model -> Model
resetStatus model =
    if model.count == maxCount then
        -- random に選んだ index に該当する sentence をセットする
        let
            s =
                pickByIndex model.sentences model.index
        in
        { model
            | shufflingState = False
            , count = 0
            , sentence = s
        }

    else
        model


shuffleSentence : Model -> Model
shuffleSentence model =
    if model.shufflingState then
        let
            randomId =
                remainderBy (List.length model.sentences) model.count
        in
        let
            randomSentence =
                pickByIndex model.sentences randomId
        in
        { model | sentence = randomSentence }

    else
        model



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every 90 Tick


maxCount : Int
maxCount =
    12



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "container-fluid" ]
        [ viewButtonGroup
        , viewCategorySelecter model
        , viewMain model
        ]


viewButtonGroup : Html Msg
viewButtonGroup =
    div [ class "row mt-sm-2" ]
        [ div [ class "col" ]
            [ div [ class "btn-group" ]
                [ button
                    [ onClick FetchSentences
                    , class "btn btn-outline-primary"
                    ]
                    [ text "Fetch" ]
                , button
                    [ onClick ShowAllSentences
                    , class "btn btn-outline-secondary"
                    ]
                    [ text "Show all" ]
                , button
                    [ onClick Pick
                    , class "btn btn-primary"
                    ]
                    [ text "Pick" ]
                ]
            ]
        ]


viewCategorySelecter : Model -> Html Msg
viewCategorySelecter model =
    div [ class "row mt-sm-2" ]
        [ div [ class "col-2" ]
            [ case model.fetchState of
                NotYet ->
                    text "hi!"

                Fetching ->
                    text "fetching..."

                Success sheets ->
                    div [] [ viewSelectLabel, viewSelect sheets ]

                Failure error ->
                    text <| Debug.toString error
            ]
        ]


viewSelectLabel : Html Msg
viewSelectLabel =
    label [ for "category-select" ] [ text "category" ]


viewSelect : Sheets -> Html Msg
viewSelect sheets =
    sheets
        |> getSheetNames
        |> (::) categoryDefault
        |> List.map text
        |> List.map List.singleton
        |> List.map (option [])
        |> select
            [ onChange Change
            , id "category-select"
            , class "form-control"
            ]


onChange : (String -> msg) -> Attribute msg
onChange handler =
    on "change" (D.map handler targetValue)


viewMain : Model -> Html Msg
viewMain model =
    case model.fetchState of
        NotYet ->
            div [] []

        Fetching ->
            div [] []

        Success sheets ->
            div [ class "row mt-sm-5" ]
                [ case model.showAllState of
                    True ->
                        div [ class "col" ]
                            [ if model.category == categoryDefault then
                                viewSheets sheets

                              else
                                let
                                    sheet =
                                        getSheetByName sheets model.category
                                in
                                case sheet of
                                    Just sh ->
                                        viewSheet sh

                                    Nothing ->
                                        div [] []
                            ]

                    False ->
                        div
                            [ class "col-10 offset-sm-1"
                            , specifyFont model
                            ]
                            [ viewSingleSentence model.sentence ]
                ]

        Failure _ ->
            div [] []


viewDebug : Model -> Html Msg
viewDebug model =
    div []
        [ p [] [ text model.category ]
        , p [] [ text <| String.fromInt model.count ]
        ]


viewSheets : Sheets -> Html Msg
viewSheets shs =
    div [] [ ol [] (List.map viewSheet shs) ]


viewSheet : Sheet -> Html Msg
viewSheet sh =
    div []
        [ h3 [] [ text sh.sheetName ]
        , ul [] (List.map viewSingleSentence sh.rows)
        ]


viewSingleSentence : Sentence -> Html Msg
viewSingleSentence stc =
    div []
        [ div [ class "display-2" ] <|
            addLineBreak stc.sentence
        , if stc.note == "" then
            div [] []

          else
            div [ class "mt-sm-4" ]
                [ button
                    [ class "btn btn-outline-info"
                    , attribute "data-toggle" "collapse"
                    , attribute "data-target" "#sentence-note"
                    , attribute "aria-expand" "false"
                    ]
                    [ text "note" ]
                , div
                    [ class "collapse"
                    , id "sentence-note"
                    ]
                    [ div
                        [ class "card card-body"
                        , class "display-3"
                        , class "text-muted"
                        ]
                      <|
                        addLineBreak stc.note
                    ]
                ]
        ]


addLineBreak : String -> List (Html Msg)
addLineBreak note =
    String.lines note
        |> List.map text
        |> List.intersperse (br [] [])


fonts : List String
fonts =
    [ "'Noto Sans JP'"
    , "'Noto Serif JP'"
    , "'M PLUS 1p'"
    , "'M PLUS Rounded 1c'"
    ]


fontsLength : Int
fontsLength =
    List.length fonts


fontsArr : Array.Array String
fontsArr =
    Array.fromList fonts


specifyFont : Model -> Attribute Msg
specifyFont model =
    let
        i =
            remainderBy fontsLength model.index
    in
    Array.get i fontsArr
        |> Maybe.withDefault ""
        |> style "font-family"



-- HTTP


getSentences : Cmd Msg
getSentences =
    Http.get
        { url = Spreadsheet.jsonAPIUrl
        , expect = Http.expectJson GotSentences sheetsDecoder
        }



-- DATA


type alias Sheets =
    List Sheet


sheetsDecoder : Decoder Sheets
sheetsDecoder =
    D.field "sheets" (D.list sheetDecoder)


type alias Sheet =
    { sheetName : String
    , rows : List Sentence
    }


sheetDecoder : Decoder Sheet
sheetDecoder =
    D.map2 Sheet
        (D.field "sheetName" D.string)
        (D.field "rows" (D.list sentenceDecoder))


type alias Sentence =
    { id : String
    , sentence : String
    , note : String
    }


sentenceDecoder : Decoder Sentence
sentenceDecoder =
    D.map3 Sentence
        (D.field "id" D.string)
        (D.field "sentence" D.string)
        (D.field "note" D.string)


getSheetNames : Sheets -> List String
getSheetNames sheets =
    List.map (\s -> s.sheetName) sheets


getSheetByName : Sheets -> String -> Maybe Sheet
getSheetByName sheets sheetName =
    List.filter (\s -> s.sheetName == sheetName) sheets
        |> List.head


getSentencesBySheetName : Sheets -> String -> List Sentence
getSentencesBySheetName sheets sheetName =
    let
        sheet =
            getSheetByName sheets sheetName
    in
    case sheet of
        Just sh ->
            sh.rows

        Nothing ->
            []
